var fmdirid=false;
var u_type,cur_page,u_checked
var page = '';
var subpage = '';
var confirmcode = false;
var confirmok = false;
var signupcode = false;
var hash = window.location.hash;
var chrome_msg=false;
var init_anoupload=false;
var blogid =false;
var pwchangecode=false;
var resetpwcode=false;
var resetpwemail='';

if (window.location.hash) page = window.location.hash.replace('#','');



function hasFlash()
{
	var f=swfobject.getFlashPlayerVersion();	
	if ((f.major >= 11) && (f.minor >= 5)) return true;
	else if ((Ext.isLinux) && (f.major >= 11)) return true;
	else return false;
}


function pagebrowse(p)
{	
	page = p;
	init_page();
}

function logout()
{	
	u_logout();
	document.location.href = '/';
}

function tmenu()
{
	if (document.getElementById('top_pullmenu').style.display == '') document.getElementById('top_pullmenu').style.display='none';
	else document.getElementById('top_pullmenu').style.display='';
}

function lmenu()
{
	if (document.getElementById('language_menu').style.display == '') document.getElementById('language_menu').style.display='none';
	else document.getElementById('language_menu').style.display='';
}


function hashchange()
{	
	var p = window.location.hash.replace('#','');
	if (d) console.log(p);	
	pagebrowse(p);
}

function parsetopmenu()
{
	var top = translate(pages['top']);
	if (u_type) top = translate(pages['topl']);
	return top;
}

function addmenuoptions()
{
	if (document.getElementById('language_menu_options'))
	{		
		var lc=0;
		for (var lng in languages) if (languages[lng].length > 0) lc++;
		var tl = lc;
		lc = Math.ceil(lc/4);
		
		var m = '<div class="nlanguage-txt-block">';
		var i=1;
		var x=1;
		for (var lng in languages)
		{
			if (languages[lng].length > 0)
			{
				m += '<a href="javascript:setlang(\'' + lng + '\');" class="nlanguage-lnk"><span class="nlanguage-tooltip"> <span class="nlanguage-tooltip-bg"> <span class="nlanguage-tooltip-main"> ' + ln2[lng] + '</span></span></span>' + ln[lng] + '</a><div class="clear"></div>';				

				if ((lc*x == i) && (i !== tl))
				{
					m+='</div><div class="nlanguage-txt-block">';
					x++;
				}
				i++;
			}
		}
		m+='</div><div class="clear"></div>';
		document.getElementById('language_menu_options').innerHTML = m;	
		document.getElementById('language_menu_selected').innerHTML = ln[lang].replace('Brasil','BR');
	}
}


function setlang(lang)
{
	if (downloading || ul_uploading)
	{									
		alert(l[375]);
		return false;
	}
	localStorage.lang = lang;
	window.location.reload();
}

function parsepage(pagehtml)
{
	pagehtml = translate(pagehtml);
	pagehtml = pagehtml.replace(/{staticpath}/g,staticpath);
	
	var top = parsetopmenu();
	
	document.getElementById('topmenufm').innerHTML ='';
	document.getElementById('topmenufm').style.display='none';
	document.getElementById('fmholder').style.display='none';
	
	if (page == 'start')
	{
		document.getElementById('bodyel').className = 'start-page';
	}
	else
	{	
		document.getElementById('bodyel').className = 'bottom-pages';	
	}
	
	document.getElementById('pageholder').style.display='';	
	document.getElementById('pageholder').innerHTML = translate(top) + pagehtml + translate(pages['bottom']);
	
	
	addmenuoptions();
	
	
	$j('#menu_hover').tooltip({ position: "bottom center"});
	$j('#language_hover').tooltip({ position: "bottom center"});
	
	if (u_type === 0)
	{	
		document.getElementById('menu_login').style.display='none';
		document.getElementById('menu_abort').style.display='';		
	}

	
	if ((page == 'developers') && (Ext.userAgent.toLowerCase().indexOf('chrome') > 0))
	{	
		$('html')[0].style.height   = 'auto';
		$('html')[0].style.overflow = 'auto';
	}
	else
	{	
		$('html')[0].style.height   = '100%';
		$('html')[0].style.overflow = 'hidden';
	}
	
	if ($(".top-head")) $(".top-head")[0].scrollIntoView();
	
	$j('#ribon_hover').tooltip({ position: "bottom center" });
}

function init_page_fm()
{
	if (d) console.log('init_page_fm()');
	if (d) console.log(extjsloaded);	
	document.getElementById('bodyel').className = '';
	if (!extjsloaded)
	{	
		if (d) console.log('Ext not ready.');
		setTimeout("init_page_fm()",250);	
	}
	else
	{
		$('html')[0].style.height   = '100%';
		$('html')[0].style.overflow = 'hidden';
		if (!init_l)
		{
			document.getElementById('pageholder').style.display='none';		
			document.getElementById('pageholder').innerHTML = '';
			
			if (init_anoupload)
			{	
				if (ul_method)
				{
					document.getElementById('topmenu').innerHTML = '';
					document.getElementById('start_button1').style.display='none';
					document.getElementById('start_uploadbutton').style.width='1px';
					document.getElementById('start_uploadbutton').style.height='1px';
				}
				else
				{
					document.getElementById('nstartholder').style.display='none';
					document.getElementById('nstartholder').innerHTML = '';				
				}
			}
			else
			{
				document.getElementById('nstartholder').style.display='none';
				document.getElementById('nstartholder').innerHTML = '';
			}
		}	
		document.getElementById('topmenufm').innerHTML = parsetopmenu();
		addmenuoptions();
		$j('#menu_hover').tooltip({ position: "bottom center"});
		$j('#language_hover').tooltip({position: "bottom center"});				
		if (!init_l) document.getElementById('fmholder').style.display='';
		if (!fmstarted) startfm();				
		else
		{
			document.getElementById('topmenufm').style.display='';
			mainpanel.doComponentLayout();
		}
	}
}



function is_fm()
{
	if ((((u_type !== false) && (page == '')) || ((u_type !== false) && (page == 'fm')) || ((u_type !== false) && (page == 'start')))) return true;
	else return false;
}

var dlid=false;
var dlkey=false;
var cn_url=false;
var init_l=true;


function init_page()
{		
	if (extjsloaded && u_checked)
	{	
		subpage='';				
		if (d) console.log(page);		
		
		if (dl_legacy_ie) document.getElementById('startswfdiv').innerHTML = '<object data="/downloader.swf" id="start_downloaderswf" type="application/x-shockwave-flash" height="0" width="0"><param name="wmode" value="transparent"><param value="always" name="allowscriptaccess"><param value="all" name="allowNetworking"></object>';
		
		if (d) console.log(page);
		
		page = page.replace('%21','!');
		
		if ((page.substr(0,1) == '!') && (page.length > 1))
		{							
			dlkey=false;
			var ar = page.substr(1,page.length-1).split('!');					
			if (d) console.log(ar);			
			if (ar[0]) dlid  = ar[0].replace(/[^a-z^A-Z^0-9^_^-]/g,"");
			if (ar[1]) dlkey = ar[1].replace(/[^a-z^A-Z^0-9^_^-]/g,"");
		}
		
		confirmcode = false;		
		pwchangecode = false;
		
		if ((page.substr(0,2) == 'fm') && (page.length > 2))
		{
			fmdirid = page.substr(2,page.length-2).replace(/[^a-z^A-Z^0-9^_^-]/g,"");
			page = 'fm';
		}
		
		if (!is_fm())
		{	
			init_l=false;
			document.getElementById('loading').style.display='none';			
		}
		
		if (page.substr(0,7) == 'confirm')
		{
			confirmcode = page.replace("confirm","");
			page = 'confirm';
		}
		

		if (page.substr(0,7) == 'pwreset')
		{
			resetpwcode = page.replace("pwreset","");
			page = 'resetpassword';
		}
		
		if (page.substr(0,5) == 'newpw')
		{
			pwchangecode = page.replace("newpw","");
			page = 'newpw';
		}
		
		if (page.substr(0,4) == 'help')
		{
			if (page.length > 4) subpage = page.substr(5,page.length-1)
			page = 'help';
		}
				
		if (page.substr(0,15) == 'copyrightnotice')
		{
			if (page.length > 15) cn_url = base64urldecode(page.substr(15,page.length-1));
			page = 'copyrightnotice';
		}
		
		if (!b_u)
		{
			try { localStorage.test = '1'; }
			catch(err) { page = 'chrome'; chrome_msg = 'an essential browser feature seems disabled and prevents you from accessing MEGA.<br>Please make sure your browser allows local data to be set.'; }	
		}	
		if ((page.substr(0,4) == 'blog') && (page.length > 4))
		{
			blogid = page.substr(5,page.length-2);		
			page = 'blogarticle';			
		}		
		
		if (page.substr(0,6) == 'signup')
		{
			signupcode = subpage = page.substr(6,page.length-1);			
			var req = 
			{ 
			  a: 'uv',
			  c: signupcode
			};			
			api_req([req],
			{ 
			  callback : function (json,params)
			  {
				if ((typeof json[0] == 'number') && (json[0] < 0))
				{				
					alert('Invalid signup code!');
					parsepage(pages['nstart']);
					init_nstart();
				}
				else
				{					
					parsepage(pages['register']);					
					init_register();
					register_signup(json[0]);				
				}
			  }
			});			
		}	
		else if (page == 'newpw')
		{		
			setpwset(pwchangecode,{callback: function(res) 
			{
				loadingDialog.hide();
				if ((res[0] == EACCESS) || (res[0] == 0)) alert(l[727]);
				else if(res[0] == EEXPIRED) alert(l[728]);
				else if(res[0] == ENOENT) alert(l[729]);
				else alert(l[200]);				
				if (u_type == 3)
				{
					page = 'account';
					parsepage(pages['account']);
					load_acc();
				}
				else
				{
					page = 'login';
					parsepage(pages['login']);
					init_login();				
				}
			}});
		}
		else if (page == 'confirm')
		{		
			var ctx = 
			{
				signupcodeok: function(email,name)
				{
					confirmok=true;
					page = 'login';
					parsepage(pages['login']);
					login_txt = l[378];
					init_login();
					document.getElementById('login_email').value = email;
					document.getElementById('login_title').innerHTML = 'Confirm';
					document.getElementById('login_button').innerHTML = 'Confirm';
					document.getElementById('login_password').value = '';
					document.getElementById('login_password').focus();				
				},
				signupcodebad: function(res)
				{
					if (res == EINCOMPLETE) alert(l[703]);										
					else if (res == ENOENT) login_txt = l[704];
					else alert(l[705] + res);					
					page = 'login';
					parsepage(pages['login']);
					init_login();
				}
			}
			verifysignupcode(confirmcode,ctx);		
		}		
		else if (u_type == 2)
		{
			parsepage(pages['key']);			
			if (typeof u_privk == 'undefined')
			{	
				genkey();
			}
		}		
		else if (page == 'login')
		{
			parsepage(pages['login']);
			init_login();
		}		
		else if (page == 'resetpassword')
		{
			api_req([{a: 'upkc', uk: resetpwcode}],
			{ 
				callback : function (json,params) 
				{
					if (typeof json[0] == 'string')
					{	
						
						resetpwemail = json[0];
						parsepage(pages['forgotpassword']);
						fp_init(true);					
					}
					else
					{
						if (json[0] == EEXPIRED) alert(l[743]);
						else alert(l[744]);
						parsepage(pages['forgotpassword']);
						fp_init(false);							
					}		
				}
			});
		}
		else if (page == 'forgotpassword')
		{
			parsepage(pages['forgotpassword']);
			fp_init(false);
		}
		else if (page == 'investors')
		{
			parsepage(pages['investors']);
		}
		else if (page == 'register')
		{
			parsepage(pages['register']);
			init_register();
		}
		else if (page == 'chrome')
		{
			parsepage(pages['chrome']);
			init_chrome();
		}
		else if (page == 'key')
		{
			parsepage(pages['key']);
		}
		else if (page == 'contact')
		{
			parsepage(pages['contact']);
		}
		else if ((page == 'help') && (subpage != ''))
		{
			parsepage(pages['help']);
			init_helpsub();
		}
		else if (page == 'help')
		{
			parsepage(pages['help']);
			init_help();
		}
		else if (page == 'privacy')
		{
			parsepage(pages['privacy']);
		}
		else if (page == 'privacycompany')
		{
			parsepage(pages['privacycompany']);
			privacycompany_init();
		}
		else if (page == 'developers')
		{
			parsepage(pages['developers']);
			dev_init();
		}
		else if (page == 'about')
		{
			parsepage(pages['about']);
		}
		else if (page == 'terms')
		{
			parsepage(pages['terms']);
		}
		else if (page == 'resellerintro')
		{
			parsepage(pages['resellerintro']);
		}
		else if (page == 'download')
		{
			parsepage(pages['download']);
		}
		else if (page == 'blog')
		{
			parsepage(pages['blog']);
			init_blog();
		}
		else if (page == 'blogarticle')
		{
			parsepage(pages['blogarticle']);
			init_blogarticle();
		}
		else if (page == 'copyright')
		{
			parsepage(pages['copyright']);
		}
		else if (page == 'resellers')
		{
			parsepage(pages['resellers']);
		}
		else if (page == 'pro')
		{
			parsepage(pages['pro']);
			init_pro();
		}
		else if (page == 'hosting')
		{
			parsepage(pages['hosting']);
		}
		else if ((page == 'resellerapp') && (!u_type))
		{
			login_txt = l[376];
			parsepage(pages['login']);
			init_login();
		}
		else if (page == 'resellerapp')
		{
			parsepage(pages['resellerapp']);
			init_resellerapp();
		}
		else if (page == 'flash')
		{
			parsepage(pages['flash']);
		}
		else if (page == 'takedown')
		{
			parsepage(pages['takedown']);
			init_takedown();
		}
		else if (page == 'takedown2')
		{
			parsepage(pages['takedown2']);
		}
		else if (page == 'done')
		{
			if (!done_text1)
			{
				done_text1 = 'Test123';
				done_text2 = 'Test1234';
			}		
			parsepage(pages['done']);
			init_done();
		}
		else if ((page.substr(0,7) == 'account') && (!u_type))
		{
			if (u_type == false)
			{
				login_txt = l[376];
				parsepage(pages['login']);
				init_login();
			}
			else
			{
				parsepage(pages['register']);
				init_register();
			}
		}
		else if (page.substr(0,7) == 'account')
		{
			parsepage(pages['account']);
			load_acc();
		}
		else if (page == 'copyrightnotice')
		{
			parsepage(pages['copyrightnotice']);
			init_cn();
		}
		else if (dlid)
		{			
			if (d) console.log(dlid);
			if (d) console.log(dlkey);
			page = 'download';
		
			parsepage(pages['download']);
			dlinfo(dlid,dlkey,false);			
		}
		else if (is_fm())
		{	
			if ((fmdirid) && (fmstarted))
			{
				if (currentdirid != fmdirid) opendirectory(fmdirid);		
			}
			init_page_fm();
		}
		else if (pages[page])
		{
			parsepage(pages[page]);
			if (init_f[page]) init_f[page]();
		}
		else
		{
			page = 'start';
			parsepage(pages['nstart']);
			init_nstart();
		}
		//setTimeout("document.title = 'MEGA';",200);
	}
	else 
	{
		if (d) console.log(extjsloaded);
		if (d) console.log(u_checked);	
	}
}







if (ie9)
{
	function checktitle()
	{
		if (document.title !== 'MEGA') document.title = 'MEGA';
		setTimeout("checktitle()",500);
	}	
	setTimeout("checktitle()",1000);
}


window.onhashchange = function()
{
	var tpage = document.location.hash;
	if ((downloading || ul_uploading))
	{			
		if ((is_fm()) && (document.location.hash.substr(0,3) == '#fm')) return false;
		var h = document.location.hash;
		document.location.hash = hash;							
		alert(l[375]);
		return false;
	}	
	if ((document.getElementById('overlay').style.display == '') && (page != 'fm'))
	{			
		document.location.hash = hash;
		return false;
	}	
	if (ext_loading_dialog)
	{			
		document.location.hash = hash;
		return false;
	}	
	dlid=false;
	hash = window.location.hash;
	if (window.location.hash) page = window.location.hash.replace('#','');
	else page = '';
	init_page();
}	



window.onbeforeunload = function ()
{
	if ((downloading) || (ul_uploading)) return l[377];
}