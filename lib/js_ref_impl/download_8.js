var dl_queue = [];
var dl_queue = [];
var dl_queue_num = 0;
var dl_retryinterval;

// 0 - FileSystem, 1 - Flash, 2 - Blob
var dl_method;

var dl_legacy_ie = (typeof XDomainRequest != 'undefined') && (typeof ArrayBuffer == 'undefined');
var dl_flash_connections;
var dl_flash_progress;

var dl_instance = 0;

var dl_blob;

var dl_key;
var dl_keyNonce;
var dl_macs;
var dl_aes;

var dl_filename;
var dl_filesize;
var dl_geturl;
var dl_bytesreceived = 0;
var dl_chunks;
var dl_chunksizes;

var downloading=false;

var dl_maxSlots = 4;
if (localStorage.dl_maxSlots) dl_maxSlots = localStorage.dl_maxSlots;

var dl_xhrs;
var dl_pos;
var dl_progress;

var dl_cipherq;
var dl_cipherqlen;

var dl_plainq;
var dl_plainqlen;

var dl_lastquotawarning;

var dl_maxWorkers = 4;
var dl_workers;
var dl_workerbusy;

var dl_write_position;

var dl_id;

function dl_dispatch_chain()
{
	if (downloading)
	{
		dl_dispatch_read();
		dl_dispatch_decryption();
		dl_dispatch_write();
	}
}

function dl_dispatch_decryption()
{
	if (use_workers)
	{
		for (var id = dl_maxWorkers; id--; )
		{
			if (!dl_workerbusy[id]) break;
		}

		if (id >= 0)
		{		
			for (var p in dl_cipherq)
			{
				dl_workerbusy[id] = 1;
			
				if (typeof(dl_workers[id]) == "object")
				{
					dl_workers[id].terminate();
					dl_workers[id] = null;
					delete dl_workers[id];
				}
				
				dl_workers[id] = new Worker('decrypter.js');
				dl_workers[id].postMessage = dl_workers[id].webkitPostMessage || dl_workers[id].postMessage;
				dl_workers[id].id = id;
				dl_workers[id].instance = dl_instance;

				dl_workers[id].onmessage = function(e)
				{
					if (this.instance == dl_instance)
					{
						if (typeof(e.data) == "string")
						{
							if (e.data[0] == '[') dl_macs[this.dl_pos] = JSON.parse(e.data);
							else if (d) console.log("WORKER" + this.id + ": '" + e.data + "'");
						}
						else
						{
							var databuf = new Uint8Array(e.data);

							if (d) console.log("WORKER" + this.id + ": Received " + databuf.length + " decrypted bytes at " + this.dl_pos);

							dl_plainq[this.dl_pos] = databuf;
							dl_plainqlen++;

							dl_workerbusy[this.id] = 0;

							dl_dispatch_chain();
						}
					}
				};

				dl_workers[id].postMessage(dl_keyNonce);

				if (d) console.log("WORKER" + id + ": Queueing " + dl_cipherq[p].length + " bytes at " + p);
				
				dl_workers[id].dl_pos = parseInt(p);
				dl_workers[id].postMessage(dl_workers[id].dl_pos/16);
				dl_workers[id].postMessage(dl_cipherq[p]);

				delete dl_cipherq[p];
				dl_cipherqlen--;
				
				break;
			}
		}
		else if (d) console.log("All worker threads are busy now.");
	}
	else
	{
		for (var p in dl_cipherq)
		{
			if (d) console.log("Decrypting pending block at " + p + " without workers...");

			dl_macs[p] = decrypt_ab_ctr(dl_aes,dl_cipherq[p],[dl_key[4],dl_key[5]],p);

			dl_plainq[p] = dl_cipherq[p];
			delete dl_cipherq[p];

			dl_cipherqlen--;
			dl_plainqlen++;
			
			break;
		}
	}
}

function dl_resume(id)
{
	if (downloading) dl_dispatch_chain();
	else
	{
		if (id) for (var i = dl_queue.length; i--; ) if (id == dl_queue[i].id) dl_queue_num = i;
		startdownload();
	}
}

var test12;

function dl_dispatch_write()
{
	if (dl_filesize == -1) return;

	if (typeof dl_plainq[dl_write_position] != "object")
	{
		if (d) console.log("Plaintext at " + dl_write_position + " still missing: " + typeof dl_plainq[dl_write_position]);
		dl_checklostchunk();
		return;
	}
	
	

	if (dl_method)
	{
		var p = dl_write_position;
		
		dl_writedata(dl_plainq[p]);

		dl_write_position += have_ab ? dl_plainq[p].length : dl_plainq[p].buffer.length;
		
		delete dl_plainq[p];
		dl_plainqlen--;
		dl_dispatch_chain();		
	}
	else
	{
		if (document.fileWriter.readyState == document.fileWriter.WRITING)
		{
			if (d) console.log("fileWriter is busy now. Please try again later.");
			return;
		}

		if (d) console.log("Writing " + dl_plainq[dl_write_position].length + " bytes of file data at dl_pos " + dl_write_position + " real_position: " + document.fileWriter.position);
		var blob = new Blob([dl_plainq[dl_write_position]]);
		delete dl_plainq[dl_write_position];

		document.fileWriter.instance = dl_instance;

		document.fileWriter.onwriteend = function()
		{
			if (this.instance == dl_instance)
			{
				if (d) console.log("fileWriter: onwriteend, position: " + this.position);
				dl_write_position = this.position;
				dl_plainqlen--;
				dl_dispatch_chain();
			}
		}

		document.fileWriter.write(blob);
	}
}

var dl_timeout;

function dl_settimer(timeout,target)
{
	if (d) console.log(timeout < 0 ? "Stopping timer" : "Starting timer " + timeout);
	if (dl_timeout) clearTimeout(dl_timeout);
	if (timeout >= 0) dl_timeout = setTimeout(target,timeout);
	else dl_timeout = undefined;
}

// try to start download at dl_queue_num
// if that download is not available, loop through the whole dl_queue and try to start
// another one
function startdownload()
{
	dl_settimer(-1);

	if (downloading)
	{
		if (d) console.log("startdownload() called with active download");
		return;
	}

	if (dl_queue_num >= dl_queue.length) dl_queue_num = dl_queue.length-1;
	
	if (dl_queue_num < 0)
	{
		if (d) console.log("startdownload() called with dl_queue_num == -1");
		return;
	}

	var dl_queue_num_start = dl_queue_num;
	var t;
	var retryin = -1;
	
	for (;;)
	{
		if (dl_queue[dl_queue_num])
		{
			if (!dl_queue[dl_queue_num].retryafter) break;
		
			if (!t) t = new Date().getTime();
		
			if (t >= dl_queue[dl_queue_num].retryafter) break;
		
			if (retryin < 0 || (dl_queue[dl_queue_num].retryafter-t < retryin))
			{
				retryin = dl_queue[dl_queue_num].retryafter-t;
				if (retryin < 0) retryin = 0;
			}
		}

		dl_queue_num++;

		if (dl_queue_num >= dl_queue.length)
		{
			if (d) console.log('Reached end of dl_queue, starting from 0');
			dl_queue_num = 0;
		}
		
		if (dl_queue_num == dl_queue_num_start)
		{
			if (d) console.log('Looped through all downloads, nothing left');
			dl_settimer(retryin,startdownload);
			
			if (retryin < 0)
			{
				if (d) console.log('Nothing left to retry, clearing dl_queue');
				dl_queue = [];
				dl_queue_num = 0;
			}
			return;
		}
	}

	downloading=true;
	
	dl_key = dl_queue[dl_queue_num].key;
	if (d) console.log("dl_key " + dl_key);		
	if (dl_queue[dl_queue_num].ph) dl_id = dl_queue[dl_queue_num].ph;
	else dl_id  = dl_queue[dl_queue_num].id;
	
	dl_geturl = '';

	dl_bytesreceived = 0;
	dl_chunksizes = new Array;

	dl_keyNonce = JSON.stringify([dl_key[0]^dl_key[4],dl_key[1]^dl_key[5],dl_key[2]^dl_key[6],dl_key[3]^dl_key[7],dl_key[4],dl_key[5]]);

	dl_macs = {};

	dl_filesize = -1;

	dl_retryinterval = 1000;

	dl_cipherq = [];
	dl_cipherqlen = 0;
	dl_plainq = [];
	dl_plainqlen = 0;
	dl_lastquotawarning = 0;
	
	dl_pos = Array(dl_maxSlots);
	dl_progress = Array(dl_maxSlots);

	if (!dl_legacy_ie)
	{
		dl_xhrs = Array(dl_maxSlots);

		for (var slot = dl_maxSlots; slot--; )
		{
			dl_xhrs[slot] = new XMLHttpRequest;
			dl_xhrs[slot].slot = slot;
			dl_pos[slot] = -1;
			dl_progress[slot] = 0;
		}
	}
	else
	{
		dl_flash_connections = 0;
		dl_flash_progress = {};
	}

	if (use_workers)
	{
		dl_workers = new Array(dl_maxWorkers);
		dl_workerbusy = new Array(dl_maxWorkers);

		for (var id = dl_maxWorkers; id--; ) dl_workerbusy[id] = 0;
	}
	else dl_aes = new sjcl.cipher.aes([dl_key[0]^dl_key[4],dl_key[1]^dl_key[5],dl_key[2]^dl_key[6],dl_key[3]^dl_key[7]]);
	
	dl_write_position = 0;

	dl_getsourceurl(startdownload2);
}

function dl_renewsourceurl()
{
	dl_getsourceurl(dl_renewsourceurl2);
}

function dl_getsourceurl(callback)
{
	req = { a : 'g', g : 1, ssl : use_ssl };

	if (dl_queue[dl_queue_num].ph) req.p = dl_queue[dl_queue_num].ph;
	else if (dl_queue[dl_queue_num].id) req.n = dl_queue[dl_queue_num].id;
	
	api_req([req],{ callback : callback });
}

function dl_renewsourceurl2(res,ctx)
{
	if (typeof res == 'object')
	{
		if (typeof res[0] == 'number')
		{
			dl_reportstatus(dl_queue_num,res[0]);
		}
		else
		{
			if (dl_queue[dl_queue_num].g)
			{
				dl_geturl = dl_queue[dl_queue_num].g;
				dl_dispatch_queue()
				return;
			}
			else if (dl_queue[dl_queue_num].e) dl_reportstatus(dl_queue_num,dl_queue[dl_queue_num].e);
		}

		dl_queue_num++;
		startdownload();
	}
}
	
function dl_reportstatus(num,code)
{
	if (dl_queue[num])
	{
		dl_queue[num].lasterror = code;
		dl_queue[num].onDownloadError(dl_queue[num].id || dl_queue[num].ph,code);
	}
}

function startdownload2(res,ctx)
{
	if (typeof res == 'object')
	{
		if (typeof res[0] == 'number')
		{
			dl_reportstatus(dl_queue_num,res[0]);
		}
		else
		{
			if (res[0].d)
			{
				dl_reportstatus(dl_queue_num,res[0].d ? 2 : 1);
				dl_queue[dl_queue_num] = false;
			}
			else if (res[0].g)
			{
				var ab = base64_to_ab(res[0].at);
				var o = dec_attr(ab,[dl_key[0]^dl_key[4],dl_key[1]^dl_key[5],dl_key[2]^dl_key[6],dl_key[3]^dl_key[7]]);

				if (typeof o == 'object' && typeof o.n == 'string') return dl_setcredentials(res[0].g,res[0].s,o.n);
				else dl_reportstatus(dl_queue_num,EKEY);
			}
			else dl_reportstatus(dl_queue_num,res[0].e);
		}
	}
	else dl_reportstatus(dl_queue_num,EAGAIN);
	
	downloading = false;
	
	dl_queue_num++;

	dl_retryinterval *= 1.2;
	
	dl_settimer(dl_retryinterval,startdownload);
}

function dl_setcredentials(g,s,n)
{
	var i;
	var p;
	var pp;

	dl_geturl = g;
	dl_filesize = s;
	dl_filename = n;

	dl_chunks = [];
	
	p = pp = 0;
	for (i = 1; i <= 8 && p < dl_filesize-i*131072; i++)
	{
		dl_chunksizes[p] = i*131072;
		dl_chunks.push(p);
		pp = p;
		p += dl_chunksizes[p];
	}

	while (p < dl_filesize)
	{
		dl_chunksizes[p] = 1048576;
		dl_chunks.push(p);
		pp = p;
		p += dl_chunksizes[p];
	}

	if (!(dl_chunksizes[pp] = dl_filesize-pp))
	{
		delete dl_chunksizes[pp];
		delete dl_chunks[dl_chunks.length-1];
	}

	if (!dl_method) dl_createtmp();	
	else
	{
		if (dl_method == 2) dl_blob = new MSBlobBuilder();
		else if (dl_method == 3)
		{
			// firefox extension:
			
			ffe_createtmp();
		
		}
		dl_run();
	}
}
	
function dl_run()
{
	document.getElementById('dllink').download = dl_filename;
	
	if (dl_filesize)
	{
		for (var slot = dl_maxSlots; slot--; ) dl_dispatch_read(slot);
		dl_queue[dl_queue_num].onDownloadStart(dl_id,dl_filename,dl_filesize);
	}
	else dl_checklostchunk();
}

function dl_checklostchunk()
{
	var i;

	if (dl_write_position == dl_filesize)
	{
		dl_retryinterval = 1000;
		
		if (dl_filesize)
		{
			var t = [];

			for (p in dl_macs) t.push(p);

			t.sort(function(a,b) { return parseInt(a)-parseInt(b) });

			for (i = 0; i < t.length; i++) t[i] = dl_macs[t[i]];

			var mac = condenseMacs(t,[dl_key[0]^dl_key[4],dl_key[1]^dl_key[5],dl_key[2]^dl_key[6],dl_key[3]^dl_key[7]]);
		}
		
		downloading = false;

		if (dl_filesize && (dl_key[6] != (mac[0]^mac[1]) || dl_key[7] != (mac[2]^mac[3])))
		{
			dl_reportstatus(dl_queue_num,EKEY);
			dl_queue[dl_queue_num] = false;
		}
		else
		{
			if (!dl_method)
			{			
				dl_queue[dl_queue_num].onBeforeDownloadComplete();
				document.getElementById('dllink').href = document.fileEntry.toURL();
				if (document.getElementById('dllink').click) document.getElementById('dllink').click();				
			}
			else if (dl_method == 1)
			{
				document.getElementById('dlswf_' + dl_id).flashdata(dl_id,'',dl_queue[dl_queue_num].n);
			}
			else if (dl_method == 2)
			{
				navigator.msSaveOrOpenBlob(dl_blob.getBlob(),dl_queue[dl_queue_num].n);
			}
			else if (dl_method == 3)
			{
				ffe_complete(dl_queue[dl_queue_num].n,dl_queue[dl_queue_num].p);
			}

			dl_queue[dl_queue_num].onDownloadComplete(dl_id);
			dl_queue[dl_queue_num] = false;
			dl_queue_num++;

			// release all downloads waiting for quota
			for (i = dl_queue.length; i--; ) if (dl_queue[i] && dl_queue[i].lasterror == EOVERQUOTA)
			{
				dl_reportstatus(i,0);
				delete dl_queue[i].retryafter;
			}
		}

		startdownload();		
	}
}

function dl_httperror(code)
{
	if (code == 509)
	{
		var t = new Date().getTime();

		if (!dl_lastquotawarning || t-dl_lastquotawarning > 55000)
		{
			dl_lastquotawarning = t;
			dl_reportstatus(dl_queue_num,code == 509 ? EOVERQUOTA : ETOOMANYCONNECTIONS);
			dl_settimer(60000,dl_dispatch_chain);
		}
		
		return;
	}

	dl_reportstatus(dl_queue_num,EAGAIN);

	dl_retryinterval *= 1.2;

	if (!dl_write_position)
	{
		dl_cancel();
		dl_queue_num++;
		dl_settimer(dl_retryinterval,startdownload);
	}
	else
	{
		if (d) console.log("Network error, retrying in " + Math.floor(dl_retryinterval) + " seconds...");
		
		dl_settimer(dl_retryinterval,code == 509 ? dl_dispatch_chain : dl_renewsourceurl);
	}
}

function flash_dlprogress(p,numbytes)
{
	dl_flash_progress[p] = numbytes;
	dl_updateprogress();
}

function dl_flashdldata(p,data,httpcode)
{
	dl_flash_connections--;

	if (data == 'ERROR' || httpcode != 200)
	{
		dl_chunks.unshift(p);
		var t = new Date().getTime();

		dl_httperror(httpcode);

		return;
	}

	data = base64urldecode(data);

	delete dl_flash_progress[p];
	dl_bytesreceived += data.length;
	
	dl_cipherq[p] = { buffer : data };
	dl_cipherqlen++;
	dl_updateprogress();

	dl_dispatch_chain();
}

function dl_dispatch_read()
{
	if (dl_cipherqlen+dl_plainqlen > dl_maxSlots+8) return;

	if (!dl_chunks.length) return;

	if (dl_legacy_ie)
	{
		if (dl_flash_connections > 6) return;
		
		dl_flash_connections++;
		
		var p = dl_chunks[0];
		dl_chunks.splice(0,1);
		flashdlchunk(p,dl_geturl + '/' + p + '-' + (p+dl_chunksizes[p]-1));
		return;
	}

	for (var slot = dl_maxSlots; slot--; )
		if (dl_pos[slot] == -1) break;

	if (slot < 0) return;

	dl_pos[slot] = dl_chunks[0];
	dl_chunks.splice(0,1);
	dl_xhrs[slot].instance = dl_instance;

	if (d) console.log("Requesting chunk " + dl_pos[slot] + "/" + dl_chunksizes[dl_pos[slot]] + " on slot " + slot + ", " + dl_chunks.length + " remaining");

	dl_xhrs[slot].onprogress = function(e) 
	{
		if (this.instance == dl_instance)
		{
			if (!dl_lastquotawarning || new Date().getTime()-dl_lastquotawarning > 55000)
			{
				if (dl_pos[this.slot] >= 0)
				{
					dl_progress[this.slot] = e.loaded;
					
					dl_updateprogress();
				}
			}
		}
	}

	dl_xhrs[slot].onreadystatechange = function()
	{
		if (this.instance == dl_instance)
		{
			if (this.readyState == this.DONE)
			{
				if (dl_pos[this.slot] >= 0)
				{
					if (this.response != null)
					{
						var p = dl_pos[this.slot];

						if (have_ab)
						{
							if (p >= 0)
							{
								if (navigator.appName != 'Opera') dl_bytesreceived += this.response.byteLength;
								dl_cipherq[p] = new Uint8Array(this.response);
							}
						}
						else
						{
							// non-IE
							if (p >= 0)
							{
								dl_bytesreceived += this.response.length;
								dl_cipherq[p] = { buffer : this.response };						
							}
						}

						dl_cipherqlen++;
						if (navigator.appName != 'Opera') dl_progress[this.slot] = 0;
						dl_updateprogress();

						dl_pos[this.slot] = -1;	
						dl_dispatch_chain();
					}
					else
					{
						if (dl_pos[this.slot] != -1)
						{
							dl_chunks.unshift(dl_pos[this.slot]);
							dl_pos[this.slot] = -1;	

							dl_httperror(this.status);
						}
					}
				}
			}
		}
	}

	dl_xhrs[slot].open('POST', dl_geturl + '/' + dl_pos[slot] + '-' + (dl_pos[slot]+dl_chunksizes[dl_pos[slot]]-1), true);
	dl_xhrs[slot].responseType = 'arraybuffer';
	dl_xhrs[slot].send();
}


function dl_updateprogress()
{
	var p = 0;

	if (dl_legacy_ie) for (var pp in dl_flash_progress) p += dl_flash_progress[pp];
	else for (var slot = dl_maxSlots; slot--; ) p += dl_progress[slot];
	
	dl_queue[dl_queue_num].onDownloadProgress(dl_id, dl_bytesreceived + p, dl_filesize);
}

function dl_writedata(data)
{
	if (dl_method == 1)
	{
		var j, k;
		var len;
		
		if (have_ab) len = data.length;
		else len = data.buffer.length;
		
		console.log(len);
		
		if (have_ab) subdata = ab_to_base64(data);
		else subdata = base64urlencode(data.buffer);

		document.getElementById('dlswf_' + dl_id).flashdata(dl_id,subdata);
	}
	else if (dl_method == 3)
	{
		ffe_writechunk(ab_to_str(data),dl_write_position);		
	}
	else
	{
		if (have_ab) dl_blob.append(dl_plainq[dl_write_position]);
		else dl_blob.append(dl_plainq[dl_write_position].buffer);
	}
}

function dl_cancel()
{
	dl_settimer(-1);
	dl_instance++;
	dl_xhrs = dl_pos = dl_workers = dl_progress = dl_cipherq = dl_plainq = dl_progress = dl_chunks = dl_chunksizes = undefined;
	downloading = false;
}

if (window.webkitRequestFileSystem)
{
	function errorHandler(e) {
	  var msg = '';

	  switch (e.code) {
		case FileError.QUOTA_EXCEEDED_ERR:
		  msg = 'QUOTA_EXCEEDED_ERR';
		  break;
		case FileError.NOT_FOUND_ERR:
		  msg = 'NOT_FOUND_ERR';
		  break;
		case FileError.SECURITY_ERR:
		  msg = 'SECURITY_ERR';
		  break;
		case FileError.INVALID_MODIFICATION_ERR:
		  msg = 'INVALID_MODIFICATION_ERR';
		  break;
		case FileError.INVALID_STATE_ERR:
		  msg = 'INVALID_STATE_ERR';
		  break;
		default:
		  msg = 'Unknown Error';
		  break;
	  };

	  if (d) console.log('Error: ' + msg);
	}

	window.webkitStorageInfo.requestQuota(TEMPORARY , 1024*1024*1024*10, function(grantedBytes) 
	{
	   console.log('Storage space granted successfully');
	}, function(e) 
	{
	  console.log('Error', e);
	});

	var dirid = "mega";

	function dl_createtmp()
	{
		window.webkitRequestFileSystem(window.TEMPORARY, 1024*1024*1024*10, dl_createtmpfile, errorHandler);
	}

	function dl_createtmpfile(fs) 
	{
		document.fs = fs;

		document.fs.root.getDirectory(dirid, {create: true}, function(dirEntry) 
		{		
			if (d) console.log('Directory "'+dirid+'" created')
			document.dirEntry = dirEntry;
		}, errorHandler);

		if (d) console.log("Opening file for writing: " + dl_id);
		fs.root.getFile(dirid + '/' + dl_id, {create: true}, function(fileEntry)
		{
			fileEntry.createWriter(function(fileWriter) 
			{		  
			  if (d) console.log('File "' + dirid + '/' + dl_id + '" created');

			  fileWriter.onerror = function(e) 
			  {
				if (d) console.log('Write failed: ' + e.toString());
			  };

			  document.fileWriter 	= fileWriter;
			  document.fileEntry 	= fileEntry;

			  dl_run();
			}, errorHandler);
		}, errorHandler);
	}
	
	dl_method = 0;
}
else if (navigator.msSaveOrOpenBlob)
{
	dl_method = 2;
}
else
{
	// Flash fallback
	dl_method = 1;
}



