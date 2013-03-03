require 'spec_helper'

class CryptoSupportTestHarness
  include Megar::CryptoSupport
end

describe Megar::CryptoSupport do
  let(:harness) { CryptoSupportTestHarness.new }

  describe "#crypto_requirements_met?" do
    subject { harness.crypto_requirements_met? }
    it "must be true - which implies OpenSSL has the required modes including CTR" do
      should be_true
    end
  end

  describe "#str_to_a32" do
    subject { harness.str_to_a32(string) }
    # expectation generation in Javascript:
    #   str_to_a32(base64urldecode('zL-S9BspoEopTUm3z3O8CA'))
    [
      { given: "\xCC\xBF\x92\xF4\e)\xA0J)MI\xB7\xCFs\xBC\b", expect: [-859860236,455712842,692930999,-814498808] },
      { given: 'a', expect: [1627389952] },
      { given: 'aaaaaaaaaaaaaaa', expect: [1633771873,1633771873,1633771873,1633771776] }
    ].each do |test_case|
      context "given #{test_case[:given]}" do
        let(:string) { test_case[:given] }
        it { should eql(test_case[:expect]) }
      end
    end
  end

  describe "#a32_to_str" do
    subject { harness.a32_to_str(a32) }
    # expectation generation in Javascript:
    #   a32_to_str([602974403,-1330001938,-1976634718,-894142530])
    [
      { given: [1633837924], expect: 'abcd' },
      { given: [602974403,-1330001938,-1976634718,-894142530], expect: "\#\xF0\xA8\xC3\xB0\xB9\xC7\xEE\x8A.\xF2\xA2\xCA\xB4w\xBE" },
      { given: [1633771873,1633771873,1633771873,1633771873], expect: 'aaaaaaaaaaaaaaaa' }
    ].each do |test_case|
      context "given #{test_case[:given]}" do
        let(:a32) { test_case[:given] }
        it { should eql(test_case[:expect]) }
      end
    end
  end

  describe "#aes_encrypt_a32" do
    subject { harness.aes_encrypt_a32(data,key) }
    # expectation generation in Javascript:
    #   key = [0,0,0,0]
    #   data = [-1965633819,-2121597728,1547823083,-1677263149]
    #   cipher = new sjcl.cipher.aes(key)
    #   cipher.encrypt(data)
    [
      { data: [0x93C467E3,0x7DB0C7A4,0xD1BE3F81,0x0152CB56], key: [0,0,0,0], expect: [887729479,-1472906423,407560426,1302943674] },
      { data: [887729479,-1472906423,407560426,1302943674], key: [602974403,-1330001938,-1976634718,-894142530], expect: [-19364982,-598654435,1840800477,-1490065331] }
    ].each do |test_case|
      context "given #{test_case[:data]}" do
        let(:key) { test_case[:key] }
        let(:data) { test_case[:data] }
        it { should eql(test_case[:expect]) }
      end
    end
  end

  describe "#aes_cbc_decrypt_a32" do
    subject { harness.aes_cbc_decrypt_a32(data,key) }
    # expectation generation in Javascript:
    #   key = prepare_key_pw('NS7j8OKCfGeEEaUK') // [1258112910,-1520042757,-243943422,-1960187198]
    #   data = [887729479,-1472906423,407560426,1302943674]
    #   cipher = new sjcl.cipher.aes(key)
    #   cipher.decrypt(data) // [480935216,755335218,-883525214,599824580]
    [
      { data: [887729479,-1472906423,407560426,1302943674], key: [1258112910,-1520042757,-243943422,-1960187198], expect: [480935216,755335218,-883525214,599824580] },
      { data: [887729479,-1472906423,407560426,1302943674], key: [0,0,0,0], expect: [-1815844893,2108737444,-776061055,22203222] },
      { data: [-19364982,-598654435,1840800477,-1490065331], key: [602974403,-1330001938,-1976634718,-894142530], expect: [887729479,-1472906423,407560426,1302943674] },
      { data: [0x93C467E3,0x7DB0C7A4,0xD1BE3F81,0x0152CB56], key: [0,0,0,0], expect: [-1965633819,-2121597728,1547823083,-1677263149] }
    ].each do |test_case|
      context "given #{test_case[:data]}" do
        let(:key) { test_case[:key] }
        let(:data) { test_case[:data] }
        it { should eql(test_case[:expect]) }
      end
    end
  end


  describe "#prepare_key" do
    subject { harness.prepare_key(data) }
    [
      { data: [0x93C467E3,0x7DB0C7A4,0xD1BE3F81,0x0152CB56], expect: [ 1611938008, 1148719119, -1340889484, -1964978551] }
    ].each do |test_case|
      context "given #{test_case[:data]}" do
        let(:data) { test_case[:data] }
        it { should eql(test_case[:expect]) }
      end
    end
  end

  describe "#decrypt_key" do
    subject { harness.decrypt_key(data,key) }
    # expectation generation in Javascript:
    #    key = prepare_key_pw('megar123456$') // [-2024856631,-2045176755,-210601452,1003386405]
    #    data = base64_to_a32("zL-S9BspoEopTUm3z3O8CA") // [-859860236,455712842,692930999,-814498808]
    #    aes = new sjcl.cipher.aes(key)
    #    master_key = decrypt_key(aes,data) // [327661033,-2034153005,1144280438,-1676633549]
    #
    #    key = prepare_key_pw('NS7j8OKCfGeEEaUK') // [1258112910,-1520042757,-243943422,-1960187198]
    #    data = base64_to_a32("7oKN6U8Y0R2ancrbWjmMew") // [-293433879,1327026461,-1700934949,1513720955]
    #    aes = new sjcl.cipher.aes(key)
    #    master_key = decrypt_key(aes,data) // [384287193,302859698,554881366,530403344]
    #
    [
      { data: [-293433879,1327026461,-1700934949,1513720955], key: [1258112910,-1520042757,-243943422,-1960187198], expect: [384287193,302859698,554881366,530403344] },
      { data: [602974403,-1330001938,-1976634718,-894142530], key: [ 1611938008, 1148719119, -1340889484, -1964978551], expect: [1393105163, -90783891, 1912327600, 1525324017] },
      { data: [-859860236,455712842,692930999,-814498808], key: [-2024856631,-2045176755,-210601452,1003386405], expect: [327661033,-2034153005,1144280438,-1676633549] },
      { data: [-859860236,455712842,692930999,-814498808], key: [602974403,-1330001938,-1976634718,-894142530], expect: [1049027610,743989201,1864038849,230624922] }
    ].each do |test_case|
      context "given #{test_case[:data]}" do
        let(:key) { test_case[:key] }
        let(:data) { test_case[:data] }
        it { should eql(test_case[:expect]) }
      end
    end
  end

  describe "#prepare_key_pw" do
    subject { harness.prepare_key_pw(password) }
    # expectation generation in Javascript:
    #   key = prepare_key_pw('NS7j8OKCfGeEEaUK')
    [
      { given: 'abcd', expect: [-1360067798,1616656778,-731604536,739132024] },
      { given: 'NS7j8OKCfGeEEaUK', expect: [1258112910,-1520042757,-243943422,-1960187198] }
    ].each do |test_case|
      context "given #{test_case[:given]}" do
        let(:password) { test_case[:given] }
        it { should eql(test_case[:expect]) }
      end
    end
  end

  describe "#base64urlencode" do
    subject { harness.base64urlencode(data) }
    [
      { given: 'abcd1234', expect: 'YWJjZDEyMzQ' }
    ].each do |test_case|
      context "given #{test_case[:given]}" do
        let(:data) { test_case[:given] }
        it { should eql(test_case[:expect]) }
      end
    end
  end

  describe "#base64urldecode" do
    subject { harness.base64urldecode(data) }
    # expectation generation in Javascript:
    #  base64urldecode('zL-S9BspoEopTUm3z3O8CA')
    [
      { given: 'zL-S9BspoEopTUm3z3O8CA', expect: "\xCC\xBF\x92\xF4\e)\xA0J)MI\xB7\xCFs\xBC\b" },
      { given: 'YWJjZDEyMzQ', expect: 'abcd1234' },
      { given: 'YXNkamJhc2RqY2JuYXNrZDtjam47a2Fqc25kO2puYXM7ZGZqbmtqYmFmdg', expect: 'asdjbasdjcbnaskd;cjn;kajsnd;jnas;dfjnkjbafv' }
    ].each do |test_case|
      context "given #{test_case[:given]}" do
        let(:data) { test_case[:given] }
        it { should eql(test_case[:expect]) }
      end
    end
  end


  describe "#a32_to_base64" do
    subject { harness.a32_to_base64(data) }
    [
      { given: [-1815844893,2108737444,-776061055,22203222], expect: 'k8Rn432wx6TRvj-BAVLLVg' },
      { given: [0x93C467E3,0x7DB0C7A4,0xD1BE3F81,0x0152CB56], expect: 'k8Rn432wx6TRvj-BAVLLVg' }
    ].each do |test_case|
      context "given #{test_case[:given]}" do
        let(:data) { test_case[:given] }
        it { should eql(test_case[:expect]) }
      end
    end
  end

  describe "#base64_to_a32" do
    subject { harness.base64_to_a32(data) }
    # expectation generation in Javascript:
    #   base64_to_a32("zL-S9BspoEopTUm3z3O8CA")
    [
      { given: 'zL-S9BspoEopTUm3z3O8CA', expect: [-859860236,455712842,692930999,-814498808] }
      # { given: 'k8Rn432wx6TRvj-BAVLLVg', expect: [-1815844893,2108737444,-776061055,22203222] }
    ].each do |test_case|
      context "given #{test_case[:given]}" do
        let(:data) { test_case[:given] }
        it { should eql(test_case[:expect]) }
      end
    end
  end


  describe "#mpi_to_a32" do
    subject { harness.mpi_to_a32(data) }
    # expectation generation in Javascript:
    #   b64 = "ABwP____"
    #   data = base64urldecode(b64) // "\x00\x1C\x0F\xFF\xFF\xFF"
    #   mpi2b(data)
    [
      { given: "\x00\x1C\x0F\xFF\xFF\xFF", expect: [0x0FFFFFFF, 0] } # this is an idiosyncratic result of the Javascript mpi2b implementation, last 0 should not be included
    ].each do |test_case|
      context "given #{test_case[:given]}" do
        let(:data) { test_case[:given] }
        it { should eql(test_case[:expect]) }
      end
    end
  end

  describe "#base64_mpi_to_a32" do
    subject { harness.base64_mpi_to_a32(data) }
    # expectation generation in Javascript:
    #   data = "CABTMUpwxe-OSvX_AhWxDzNu-fvisC9oRNxV97EjmBDLmLvyrEkdWRy4jAxQBOEFiqTe8bvH5EJ_HIxg_reA83kFB8UkHp359CPIceDwrTfS1pm3_onh7rWOdanzTXdixqiDRWIPo5dEfsIJixMIXtlBONla8TlTpc6sQ5NsysqMNYBaHD-5Npqj01s-pjkfSVwrtGSVU_b0JlT8acBemb8cukeXYSXaVf6ILgnBGkFYNyzSN5wmDDOU8tySoyKTtaPV9QDym0CrrxeNCYZPeawQQ4C85_dmJTJwSDyUu3ApocY2LPMYvRzo2CEP80eLuLHTSSp8O9_LMi7MrSJxCM9m"
    #   mpi2b(base64urldecode(data))
    [
      # { given: "CABTMUpwxe-OSvX_AhWxDzNu-fvisC9oRNxV97EjmBDLmLvyrEkdWRy4jAxQBOEFiqTe8bvH5EJ_HIxg_reA83kFB8UkHp359CPIceDwrTfS1pm3_onh7rWOdanzTXdixqiDRWIPo5dEfsIJixMIXtlBONla8TlTpc6sQ5NsysqMNYBaHD-5Npqj01s-pjkfSVwrtGSVU_b0JlT8acBemb8cukeXYSXaVf6ILgnBGkFYNyzSN5wmDDOU8tySoyKTtaPV9QDym0CrrxeNCYZPeawQQ4C85_dmJTJwSDyUu3ApocY2LPMYvRzo2CEP80eLuLHTSSp8O9_LMi7MrSJxCM9m",
      #   expect: [ 17354598,214618663,...,53561968,5] (length 74)
      # }
      { given: 'CABTMUpwxe-OSvX_AhWxDzNu-fvisC9oRNxV97EjmBDLmLvyrEkdWRy4jAxQBOEFiqTe8bvH5EJ_HIxg_reA83kFB8UkHp359CPIceDwrTfS1pm3_onh7rWOdanzTXdixqiDRWIPo5dEfsIJixMIXtlBONla8TlTpc6sQ5NsysqMNYBaHD-5Npqj01s-pjkfSVwrtGSVU_b0JlT8acBemb8cukeXYSXaVf6ILgnBGkFYNyzSN5wmDDOU8tySoyKTtaPV9QDym0CrrxeNCYZPeawQQ4C85_dmJTJwSDyUu3ApocY2LPMYvRzo2CEP80eLuLHTSSp8O9_LMi7MrSJxCM9m',
        expect: { length: 74, first: 17354598, last: 5 } },
      { given: 'BADOtDj2VVSPV2P3DpYOE-n-AkudPs-jvZg4_0T-uB-Vqr5M6PKmN5XrmPX-1JCzl2eeNHBT5vHRCMi0BfKQLplcxiMJAWWLDXDysbAxYRx7QpXlekjmpS3M7MmGdGAP4CK2P802oBGBayBvhVLh-2tjIO6oLyq_SOaOl2b72BT4Gw',
        expect: { length: 37, first: 135591963, last: 52916 } },
      { given: 'AAEB', expect: { length: 1, first: 1 } },
      { given: "ABwP____", expect: { length: 2, first: 0x0FFFFFFF, last: 0 } }
    ].each do |test_case|
      context "given #{test_case[:given]}" do
        let(:data) { test_case[:given] }
        its(:length) { should eql(test_case[:expect][:length]) }
        its(:first)  { should eql(test_case[:expect][:first]) }  if test_case[:expect][:first]
        its(:last)   { should eql(test_case[:expect][:last]) }   if test_case[:expect][:last]
      end
    end
  end

  describe "#base64_mpi_to_bn" do
    subject { harness.base64_mpi_to_bn(data) }
    let(:data) { "CABTMUpwxe-OSvX_AhWxDzNu-fvisC9oRNxV97EjmBDLmLvyrEkdWRy4jAxQBOEFiqTe8bvH5EJ_HIxg_reA83kFB8UkHp359CPIceDwrTfS1pm3_onh7rWOdanzTXdixqiDRWIPo5dEfsIJixMIXtlBONla8TlTpc6sQ5NsysqMNYBaHD-5Npqj01s-pjkfSVwrtGSVU_b0JlT8acBemb8cukeXYSXaVf6ILgnBGkFYNyzSN5wmDDOU8tySoyKTtaPV9QDym0CrrxeNCYZPeawQQ4C85_dmJTJwSDyUu3ApocY2LPMYvRzo2CEP80eLuLHTSSp8O9_LMi7MrSJxCM9m" }
    it { should eql(10502085503323500781668964017618508609411322157602252889058120375390234037936305190318468520089061587385422392468906441970388809208568726068567802356382375886770719186286579637487202524290928558697462287469498082331441069974866156504895644732315656764553928491941718091843907868083134643930511260213733744807826400737798825300540532269568079807932475504054890343173139777024447054332150293043219564634033889501152496876605674176404518453389630198251852934504321636321021090323912128727555904455606013476719568342420710593762431258548723102683181657773609963093684806746300973185952810254832251507735647127973472554854) }
  end

  describe "#decrypt_base64_to_a32" do
    subject { harness.decrypt_base64_to_a32(data,key) }
    # expectation generation in Javascript:
    #    data = "3SKcQouWFdemgOQWwn_UUcCnHRNUZA0I5og99p_rYe6p2z16CY_qsbjOA5T59g3ClK6afQ9T0-lic79vtPsmRFWd7CY8EbXqZgX8gY8ZmiH0GZpCR57eOoIafpVzXU-OXrcGeJ_fOHQHDj7uEtF6lNaBdLPhdRkhYVno0DmdTcVfE939ESBmsBw_hCNUaicAmYSG1n_fdsiPs0UIOY0m2pjS1TZ-UfUZiLIxJnIujmteEKEWrOIMLnHXVR-V7S_2kZEzgOiRnrDvUIvcItP1xJ3dEvqIFPTTqVDHfEua4wnZPhPwiFg5awLudKigL2MS7kpmg9IuLTeCKytNpcOS9s24FCdIJCtsGqTXccY73Vj8rnRnjjd0iRV83XGpSPvwOa6-IPhhphGWgMNr4atlQzYHq4z3NBMMj9l8LnSOWO6KbUpTuqeQniO_YSQ_TbzjC-3cAEBjB7MpjSuBLexv3JygnpYiWmOJnUoojH3pezGNoNePtshsEllelcMa1_1c1cuJ2stH59HcTgB0u6-cpYqupeHqZB9Bn6U-eVjV1Ut-8LkzkTZjuGmt4YZZdJ-nZrkgsDkcpEFKfmupYDv8_9y69zOQaFXQ8v90KB2DawNWSEDRbAx-EFfu3rIsA3Hz2a9w-wVQQ8PD0C94kn57y4iyYbZDCu9Pal8V27J8eyUCqMh1kYlBkinuat3a2zKjT6bL6Tds6TkLUuzefO6DoPUQGTBZK8ZYi7QotUGI8xYzg6T26vDFQcgaQngSD0ZhZaKeQXdvRI_qjEZqg5Rt1VYZlJF42cinJD0N5blYewxy44Ps5oIAkR8iGjAgVL3KI_LsThWaCEKxTM0ScVGdYoh0vuSdIpAKVQVX_qfC8D0"
    #    key = [1049027610,743989201,1864038849,230624922]
    #    data_a32 = base64_to_a32(data)
    #    aes = new sjcl.cipher.aes(key)
    #    result_a32 = decrypt_key(aes,data_a32)
    [
      {
        data: "3SKcQouWFdemgOQWwn_UUcCnHRNUZA0I5og99p_rYe6p2z16CY_qsbjOA5T59g3ClK6afQ9T0-lic79vtPsmRFWd7CY8EbXqZgX8gY8ZmiH0GZpCR57eOoIafpVzXU-OXrcGeJ_fOHQHDj7uEtF6lNaBdLPhdRkhYVno0DmdTcVfE939ESBmsBw_hCNUaicAmYSG1n_fdsiPs0UIOY0m2pjS1TZ-UfUZiLIxJnIujmteEKEWrOIMLnHXVR-V7S_2kZEzgOiRnrDvUIvcItP1xJ3dEvqIFPTTqVDHfEua4wnZPhPwiFg5awLudKigL2MS7kpmg9IuLTeCKytNpcOS9s24FCdIJCtsGqTXccY73Vj8rnRnjjd0iRV83XGpSPvwOa6-IPhhphGWgMNr4atlQzYHq4z3NBMMj9l8LnSOWO6KbUpTuqeQniO_YSQ_TbzjC-3cAEBjB7MpjSuBLexv3JygnpYiWmOJnUoojH3pezGNoNePtshsEllelcMa1_1c1cuJ2stH59HcTgB0u6-cpYqupeHqZB9Bn6U-eVjV1Ut-8LkzkTZjuGmt4YZZdJ-nZrkgsDkcpEFKfmupYDv8_9y69zOQaFXQ8v90KB2DawNWSEDRbAx-EFfu3rIsA3Hz2a9w-wVQQ8PD0C94kn57y4iyYbZDCu9Pal8V27J8eyUCqMh1kYlBkinuat3a2zKjT6bL6Tds6TkLUuzefO6DoPUQGTBZK8ZYi7QotUGI8xYzg6T26vDFQcgaQngSD0ZhZaKeQXdvRI_qjEZqg5Rt1VYZlJF42cinJD0N5blYewxy44Ps5oIAkR8iGjAgVL3KI_LsThWaCEKxTM0ScVGdYoh0vuSdIpAKVQVX_qfC8D0",
        key: [1049027610,743989201,1864038849,230624922],
        expect: { length: 164, first_4: [67161780,955667796,-1890098185,244715027], last: 702938221 }
      }
    ].each do |test_case|
      context "given #{test_case[:data]}" do
        let(:data) { test_case[:data] }
        let(:key) { test_case[:key] }
        it "should match expectations" do
          subject.length.should eql(test_case[:expect][:length])
          subject[0,4].should eql(test_case[:expect][:first_4])
          subject.last.should eql(test_case[:expect][:last])
        end
      end
    end
  end

  describe "#decrypt_base64_to_str" do
    subject { harness.decrypt_base64_to_str(data,key) }
    # expectation generation in Javascript:
    #    data = "3SKcQouWFdemgOQWwn_UUcCnHRNUZA0I5og99p_rYe6p2z16CY_qsbjOA5T59g3ClK6afQ9T0-lic79vtPsmRFWd7CY8EbXqZgX8gY8ZmiH0GZpCR57eOoIafpVzXU-OXrcGeJ_fOHQHDj7uEtF6lNaBdLPhdRkhYVno0DmdTcVfE939ESBmsBw_hCNUaicAmYSG1n_fdsiPs0UIOY0m2pjS1TZ-UfUZiLIxJnIujmteEKEWrOIMLnHXVR-V7S_2kZEzgOiRnrDvUIvcItP1xJ3dEvqIFPTTqVDHfEua4wnZPhPwiFg5awLudKigL2MS7kpmg9IuLTeCKytNpcOS9s24FCdIJCtsGqTXccY73Vj8rnRnjjd0iRV83XGpSPvwOa6-IPhhphGWgMNr4atlQzYHq4z3NBMMj9l8LnSOWO6KbUpTuqeQniO_YSQ_TbzjC-3cAEBjB7MpjSuBLexv3JygnpYiWmOJnUoojH3pezGNoNePtshsEllelcMa1_1c1cuJ2stH59HcTgB0u6-cpYqupeHqZB9Bn6U-eVjV1Ut-8LkzkTZjuGmt4YZZdJ-nZrkgsDkcpEFKfmupYDv8_9y69zOQaFXQ8v90KB2DawNWSEDRbAx-EFfu3rIsA3Hz2a9w-wVQQ8PD0C94kn57y4iyYbZDCu9Pal8V27J8eyUCqMh1kYlBkinuat3a2zKjT6bL6Tds6TkLUuzefO6DoPUQGTBZK8ZYi7QotUGI8xYzg6T26vDFQcgaQngSD0ZhZaKeQXdvRI_qjEZqg5Rt1VYZlJF42cinJD0N5blYewxy44Ps5oIAkR8iGjAgVL3KI_LsThWaCEKxTM0ScVGdYoh0vuSdIpAKVQVX_qfC8D0"
    #    key = [1049027610,743989201,1864038849,230624922]
    #    data_a32 = base64_to_a32(data)
    #    aes = new sjcl.cipher.aes(key)
    #    result_a32 = decrypt_key(aes,data_a32)
    #    result_str = a32_to_str(result_a32)
    [
      {
        data: "3SKcQouWFdemgOQWwn_UUcCnHRNUZA0I5og99p_rYe6p2z16CY_qsbjOA5T59g3ClK6afQ9T0-lic79vtPsmRFWd7CY8EbXqZgX8gY8ZmiH0GZpCR57eOoIafpVzXU-OXrcGeJ_fOHQHDj7uEtF6lNaBdLPhdRkhYVno0DmdTcVfE939ESBmsBw_hCNUaicAmYSG1n_fdsiPs0UIOY0m2pjS1TZ-UfUZiLIxJnIujmteEKEWrOIMLnHXVR-V7S_2kZEzgOiRnrDvUIvcItP1xJ3dEvqIFPTTqVDHfEua4wnZPhPwiFg5awLudKigL2MS7kpmg9IuLTeCKytNpcOS9s24FCdIJCtsGqTXccY73Vj8rnRnjjd0iRV83XGpSPvwOa6-IPhhphGWgMNr4atlQzYHq4z3NBMMj9l8LnSOWO6KbUpTuqeQniO_YSQ_TbzjC-3cAEBjB7MpjSuBLexv3JygnpYiWmOJnUoojH3pezGNoNePtshsEllelcMa1_1c1cuJ2stH59HcTgB0u6-cpYqupeHqZB9Bn6U-eVjV1Ut-8LkzkTZjuGmt4YZZdJ-nZrkgsDkcpEFKfmupYDv8_9y69zOQaFXQ8v90KB2DawNWSEDRbAx-EFfu3rIsA3Hz2a9w-wVQQ8PD0C94kn57y4iyYbZDCu9Pal8V27J8eyUCqMh1kYlBkinuat3a2zKjT6bL6Tds6TkLUuzefO6DoPUQGTBZK8ZYi7QotUGI8xYzg6T26vDFQcgaQngSD0ZhZaKeQXdvRI_qjEZqg5Rt1VYZlJF42cinJD0N5blYewxy44Ps5oIAkR8iGjAgVL3KI_LsThWaCEKxTM0ScVGdYoh0vuSdIpAKVQVX_qfC8D0",
        key: [1049027610,743989201,1864038849,230624922],
        expect: { count: 656, first_8_chars: [4,0,206,180,56,246,85,84] }
      }
    ].each do |test_case|
      context "given #{test_case[:data]}" do
        let(:data) { test_case[:data] }
        let(:key) { test_case[:key] }
        it "should match expectations" do
          subject.size.should eql(test_case[:expect][:count])
          subject[0,8].bytes.map{|c| c }.should eql(test_case[:expect][:first_8_chars])
        end
      end
    end
  end

  describe "#decompose_rsa_private_key" do
    let(:decompose_rsa_private_key) { harness.decompose_rsa_private_key(data) }
    let(:master_key) { [1049027610,743989201,1864038849,230624922] }
    let(:privk) { "3SKcQouWFdemgOQWwn_UUcCnHRNUZA0I5og99p_rYe6p2z16CY_qsbjOA5T59g3ClK6afQ9T0-lic79vtPsmRFWd7CY8EbXqZgX8gY8ZmiH0GZpCR57eOoIafpVzXU-OXrcGeJ_fOHQHDj7uEtF6lNaBdLPhdRkhYVno0DmdTcVfE939ESBmsBw_hCNUaicAmYSG1n_fdsiPs0UIOY0m2pjS1TZ-UfUZiLIxJnIujmteEKEWrOIMLnHXVR-V7S_2kZEzgOiRnrDvUIvcItP1xJ3dEvqIFPTTqVDHfEua4wnZPhPwiFg5awLudKigL2MS7kpmg9IuLTeCKytNpcOS9s24FCdIJCtsGqTXccY73Vj8rnRnjjd0iRV83XGpSPvwOa6-IPhhphGWgMNr4atlQzYHq4z3NBMMj9l8LnSOWO6KbUpTuqeQniO_YSQ_TbzjC-3cAEBjB7MpjSuBLexv3JygnpYiWmOJnUoojH3pezGNoNePtshsEllelcMa1_1c1cuJ2stH59HcTgB0u6-cpYqupeHqZB9Bn6U-eVjV1Ut-8LkzkTZjuGmt4YZZdJ-nZrkgsDkcpEFKfmupYDv8_9y69zOQaFXQ8v90KB2DawNWSEDRbAx-EFfu3rIsA3Hz2a9w-wVQQ8PD0C94kn57y4iyYbZDCu9Pal8V27J8eyUCqMh1kYlBkinuat3a2zKjT6bL6Tds6TkLUuzefO6DoPUQGTBZK8ZYi7QotUGI8xYzg6T26vDFQcgaQngSD0ZhZaKeQXdvRI_qjEZqg5Rt1VYZlJF42cinJD0N5blYewxy44Ps5oIAkR8iGjAgVL3KI_LsThWaCEKxTM0ScVGdYoh0vuSdIpAKVQVX_qfC8D0" }
    let(:data) { harness.decrypt_base64_to_str(privk, master_key) }
    {
      "p" =>  {
        index: 0,
        value: 145152480967442902710798365717824992407539346469007950427947366246418381110497813913858957184058405066632963688414200899762074556635208659933679812460151505046070928204691401275085086735464744077411206367875411771694473049724208018450885347494899144266437372521383994850220996849268745979417013187349849634843
      },
      "q" =>  {
        index: 1,
        value: 168954398786765849191397563548727872242680592890703379738251630959342408442654540439639636383830987645538349601800075764540793199627780254598326754715698681619610952393034627896645230178408131025377491566528255043082418659344085645573554592452837354761723985865145763294326144330279484715521705617485134759141
      },
      "d" =>  {
        index: 2,
        value: 12983373611079770211598532059277454574873142790933720755590694119490820724884320773416062882872824441407372114886530726474979688565347545388995368928786174580865050206056588702714047747117203947610116835797727211967502240199908615095083794940126702458539176340055473274185983336006544169353743065050853660077890672872837121852471639967733140753846470653509594838648433786451039871566965471109413962221372977032372323023277197880477708795783672178465649341215154594913545491105371339761229791332444362145738176132020340880433834911670388940905488618362858862479443215147800580019791462743546344709458220309095035153113
      },
      "u" =>  {
        index: 3,
        value: 142281187671710416869275196755125318539473540637032484403888464391289938418112669687981856743914459731863778035997945316748255907504882215849378865708087640335269803246793543314284773670481750851308061490898252628799994463123391676396043625029999665330718877331066039172562710647546041034169018526295459116796
      }
    }.each do |component,expectations|
      describe component do
        subject { decompose_rsa_private_key[expectations[:index]] }
        it { should eql(expectations[:value]) }
      end
    end
  end

  describe "#decompose_rsa_private_key_a32" do
    subject { harness.decompose_rsa_private_key_a32(data) }
    # expectation generation in Javascript:
    #    password = '4leBd7TqgPwTZTByBbHfXo0E'
    #    aes = new sjcl.cipher.aes(prepare_key_pw(password))
    #    k = "zL-S9BspoEopTUm3z3O8CA"
    #    key = base64_to_a32(k)
    #    master_key = decrypt_key(aes,key) // [1049027610,743989201,1864038849,230624922]
    #
    #    privk = "3SKcQouWFdemgOQWwn_UUcCnHRNUZA0I5og99p_rYe6p2z16CY_qsbjOA5T59g3ClK6afQ9T0-lic79vtPsmRFWd7CY8EbXqZgX8gY8ZmiH0GZpCR57eOoIafpVzXU-OXrcGeJ_fOHQHDj7uEtF6lNaBdLPhdRkhYVno0DmdTcVfE939ESBmsBw_hCNUaicAmYSG1n_fdsiPs0UIOY0m2pjS1TZ-UfUZiLIxJnIujmteEKEWrOIMLnHXVR-V7S_2kZEzgOiRnrDvUIvcItP1xJ3dEvqIFPTTqVDHfEua4wnZPhPwiFg5awLudKigL2MS7kpmg9IuLTeCKytNpcOS9s24FCdIJCtsGqTXccY73Vj8rnRnjjd0iRV83XGpSPvwOa6-IPhhphGWgMNr4atlQzYHq4z3NBMMj9l8LnSOWO6KbUpTuqeQniO_YSQ_TbzjC-3cAEBjB7MpjSuBLexv3JygnpYiWmOJnUoojH3pezGNoNePtshsEllelcMa1_1c1cuJ2stH59HcTgB0u6-cpYqupeHqZB9Bn6U-eVjV1Ut-8LkzkTZjuGmt4YZZdJ-nZrkgsDkcpEFKfmupYDv8_9y69zOQaFXQ8v90KB2DawNWSEDRbAx-EFfu3rIsA3Hz2a9w-wVQQ8PD0C94kn57y4iyYbZDCu9Pal8V27J8eyUCqMh1kYlBkinuat3a2zKjT6bL6Tds6TkLUuzefO6DoPUQGTBZK8ZYi7QotUGI8xYzg6T26vDFQcgaQngSD0ZhZaKeQXdvRI_qjEZqg5Rt1VYZlJF42cinJD0N5blYewxy44Ps5oIAkR8iGjAgVL3KI_LsThWaCEKxTM0ScVGdYoh0vuSdIpAKVQVX_qfC8D0"
    #    key = base64_to_a32(privk)
    #    aes = new sjcl.cipher.aes(master_key)
    #    rsa_private_key = decrypt_key(aes,key)
    #
    #    privk = a32_to_str(rsa_private_key) // length = 656
    #    rsa_privk = Array(4);
    #    // decompose private key
    #    //for (var i = 0; i < 4; i++)
    #    i = 0
    #    l = ((privk.charCodeAt(0)*256+privk.charCodeAt(1)+7)>>3)+2 // 130
    #    privk_part = privk.substr(0,l)
    #       data = base64urlencode(privk_part) // "BADOtDj2VVSPV2P3DpYOE-n-AkudPs-jvZg4_0T-uB-Vqr5M6PKmN5XrmPX-1JCzl2eeNHBT5vHRCMi0BfKQLplcxiMJAWWLDXDysbAxYRx7QpXlekjmpS3M7MmGdGAP4CK2P802oBGBayBvhVLh-2tjIO6oLyq_SOaOl2b72BT4Gw"
    #    rsa_privk[i] = mpi2b(privk_part) // array [ 135591963, ..., 52916 ] length = 37
    #    if (typeof rsa_privk[i] == 'number') break; // "object"
    #    privk = privk.substr(l)
    #    i = 1
    #    l = ((privk.charCodeAt(0)*256+privk.charCodeAt(1)+7)>>3)+2 // 130
    #    privk_part = privk.substr(0,l)
    #    rsa_privk[i] = mpi2b(privk_part) // array [ 203883749, ..., 61593 ] length = 37
    #    if (typeof rsa_privk[i] == 'number') break; // "object"
    #    privk = privk.substr(l)
    #    i = 2
    #    l = ((privk.charCodeAt(0)*256+privk.charCodeAt(1)+7)>>3)+2 // 258
    #    privk_part = privk.substr(0,l)
    #    rsa_privk[i] = mpi2b(privk_part) // array [ 140749529, ..., 6 ] length = 74
    #    if (typeof rsa_privk[i] == 'number') break; // "object"
    #    privk = privk.substr(l)
    #    i = 3
    #    l = ((privk.charCodeAt(0)*256+privk.charCodeAt(1)+7)>>3)+2 // 130
    #    privk_part = privk.substr(0,l)
    #    rsa_privk[i] = mpi2b(privk_part) // array [ 119289596, ..., 51869 ] length = 37
    #    if (typeof rsa_privk[i] == 'number') break; // "object"
    #    privk = privk.substr(l)
    let(:master_key) { [1049027610,743989201,1864038849,230624922] }
    let(:privk) { "3SKcQouWFdemgOQWwn_UUcCnHRNUZA0I5og99p_rYe6p2z16CY_qsbjOA5T59g3ClK6afQ9T0-lic79vtPsmRFWd7CY8EbXqZgX8gY8ZmiH0GZpCR57eOoIafpVzXU-OXrcGeJ_fOHQHDj7uEtF6lNaBdLPhdRkhYVno0DmdTcVfE939ESBmsBw_hCNUaicAmYSG1n_fdsiPs0UIOY0m2pjS1TZ-UfUZiLIxJnIujmteEKEWrOIMLnHXVR-V7S_2kZEzgOiRnrDvUIvcItP1xJ3dEvqIFPTTqVDHfEua4wnZPhPwiFg5awLudKigL2MS7kpmg9IuLTeCKytNpcOS9s24FCdIJCtsGqTXccY73Vj8rnRnjjd0iRV83XGpSPvwOa6-IPhhphGWgMNr4atlQzYHq4z3NBMMj9l8LnSOWO6KbUpTuqeQniO_YSQ_TbzjC-3cAEBjB7MpjSuBLexv3JygnpYiWmOJnUoojH3pezGNoNePtshsEllelcMa1_1c1cuJ2stH59HcTgB0u6-cpYqupeHqZB9Bn6U-eVjV1Ut-8LkzkTZjuGmt4YZZdJ-nZrkgsDkcpEFKfmupYDv8_9y69zOQaFXQ8v90KB2DawNWSEDRbAx-EFfu3rIsA3Hz2a9w-wVQQ8PD0C94kn57y4iyYbZDCu9Pal8V27J8eyUCqMh1kYlBkinuat3a2zKjT6bL6Tds6TkLUuzefO6DoPUQGTBZK8ZYi7QotUGI8xYzg6T26vDFQcgaQngSD0ZhZaKeQXdvRI_qjEZqg5Rt1VYZlJF42cinJD0N5blYewxy44Ps5oIAkR8iGjAgVL3KI_LsThWaCEKxTM0ScVGdYoh0vuSdIpAKVQVX_qfC8D0" }
    let(:data) {
      harness.decrypt_base64_to_str(privk, master_key)
    }
    it "should be a valid RSA key deconstruct" do
      subject.length.should eql(4)
      part = subject[0]
      part.length.should eql(37)
      part.first.should eql(135591963)
      part.last.should eql(52916)
      part = subject[1]
      part.length.should eql(37)
      part.first.should eql(203883749)
      part.last.should eql(61593)
      part = subject[2]
      part.length.should eql(74)
      part.first.should eql(140749529)
      part.last.should eql(6)
      part = subject[3]
      part.length.should eql(37)
      part.first.should eql(119289596)
      part.last.should eql(51869)
    end
  end

  describe "#decrypt_session_id" do
    subject { harness.decrypt_session_id(rsa_private_key,csid) }
    let(:rsa_private_key) { 'somthing' }
    let(:csid) { 'somthing' }

  end

  describe "#rsa_decrypt" do
    # expectation generation in Javascript:
    #
    # master_key = [1049027610,743989201,1864038849,230624922]
    # privk = "3SKcQouWFdemgOQWwn_UUcCnHRNUZA0I5og99p_rYe6p2z16CY_qsbjOA5T59g3ClK6afQ9T0-lic79vtPsmRFWd7CY8EbXqZgX8gY8ZmiH0GZpCR57eOoIafpVzXU-OXrcGeJ_fOHQHDj7uEtF6lNaBdLPhdRkhYVno0DmdTcVfE939ESBmsBw_hCNUaicAmYSG1n_fdsiPs0UIOY0m2pjS1TZ-UfUZiLIxJnIujmteEKEWrOIMLnHXVR-V7S_2kZEzgOiRnrDvUIvcItP1xJ3dEvqIFPTTqVDHfEua4wnZPhPwiFg5awLudKigL2MS7kpmg9IuLTeCKytNpcOS9s24FCdIJCtsGqTXccY73Vj8rnRnjjd0iRV83XGpSPvwOa6-IPhhphGWgMNr4atlQzYHq4z3NBMMj9l8LnSOWO6KbUpTuqeQniO_YSQ_TbzjC-3cAEBjB7MpjSuBLexv3JygnpYiWmOJnUoojH3pezGNoNePtshsEllelcMa1_1c1cuJ2stH59HcTgB0u6-cpYqupeHqZB9Bn6U-eVjV1Ut-8LkzkTZjuGmt4YZZdJ-nZrkgsDkcpEFKfmupYDv8_9y69zOQaFXQ8v90KB2DawNWSEDRbAx-EFfu3rIsA3Hz2a9w-wVQQ8PD0C94kn57y4iyYbZDCu9Pal8V27J8eyUCqMh1kYlBkinuat3a2zKjT6bL6Tds6TkLUuzefO6DoPUQGTBZK8ZYi7QotUGI8xYzg6T26vDFQcgaQngSD0ZhZaKeQXdvRI_qjEZqg5Rt1VYZlJF42cinJD0N5blYewxy44Ps5oIAkR8iGjAgVL3KI_LsThWaCEKxTM0ScVGdYoh0vuSdIpAKVQVX_qfC8D0"
    # key = base64_to_a32(privk)
    # aes = new sjcl.cipher.aes(master_key)
    # rsa_private_key = decrypt_key(aes,key)
    # //::= decrypt_base64_to_str
    #
    # privk = a32_to_str(rsa_private_key)
    # rsa_privk = Array(4)
    # // decompose private key
    # for (var i = 0; i < 4; i++) {
    #   l = ((privk.charCodeAt(0)*256+privk.charCodeAt(1)+7)>>3)+2 // 130
    #   privk_part = privk.substr(0,l)
    #     data = base64urlencode(privk_part)
    #   rsa_privk[i] = mpi2b(privk_part)
    #   if (typeof rsa_privk[i] == 'number') break;
    #   privk = privk.substr(l)
    # }
    # //::= decompose_rsa_private_key
    #
    # csid = "CABTMUpwxe-OSvX_AhWxDzNu-fvisC9oRNxV97EjmBDLmLvyrEkdWRy4jAxQBOEFiqTe8bvH5EJ_HIxg_reA83kFB8UkHp359CPIceDwrTfS1pm3_onh7rWOdanzTXdixqiDRWIPo5dEfsIJixMIXtlBONla8TlTpc6sQ5NsysqMNYBaHD-5Npqj01s-pjkfSVwrtGSVU_b0JlT8acBemb8cukeXYSXaVf6ILgnBGkFYNyzSN5wmDDOU8tySoyKTtaPV9QDym0CrrxeNCYZPeawQQ4C85_dmJTJwSDyUu3ApocY2LPMYvRzo2CEP80eLuLHTSSp8O9_LMi7MrSJxCM9m"
    # t = mpi2b(base64urldecode(csid))
    # // length: 74, first: 17354598, last: 5
    # //::= base64_mpi_to_a32
    #
    # //if (i == 4 && privk.length < 16)
    # // r = [k,base64urlencode(b2s(RSAdecrypt(t,rsa_privk[2],rsa_privk[0],rsa_privk[1],rsa_privk[3])).substr(0,43)),rsa_privk];
    # csid_decrypt = RSAdecrypt(t,rsa_privk[2],rsa_privk[0],rsa_privk[1],rsa_privk[3]) // (m, d, p, q, u)
    # // length: 73, first: 120147264, last: 14003132
    # csid_decrypt_str = b2s(csid_decrypt)
    # csid_decrypt_s43 = csid_decrypt_str.substr(0,43)
    # csid_decrypt_b64 = base64urlencode(csid_decrypt_s43)
    # // "1au8GQLcKSCkswqio-0PHmFNdXZjYU1vZFhjr1rVWm_USjjSvFhQZbVfDA"
    #
    # k = base64_to_a32("zL-S9BspoEopTUm3z3O8CA")
    # r = [k,csid_decrypt_b64,rsa_privk]
    #
    let(:privk_encoded) { "3SKcQouWFdemgOQWwn_UUcCnHRNUZA0I5og99p_rYe6p2z16CY_qsbjOA5T59g3ClK6afQ9T0-lic79vtPsmRFWd7CY8EbXqZgX8gY8ZmiH0GZpCR57eOoIafpVzXU-OXrcGeJ_fOHQHDj7uEtF6lNaBdLPhdRkhYVno0DmdTcVfE939ESBmsBw_hCNUaicAmYSG1n_fdsiPs0UIOY0m2pjS1TZ-UfUZiLIxJnIujmteEKEWrOIMLnHXVR-V7S_2kZEzgOiRnrDvUIvcItP1xJ3dEvqIFPTTqVDHfEua4wnZPhPwiFg5awLudKigL2MS7kpmg9IuLTeCKytNpcOS9s24FCdIJCtsGqTXccY73Vj8rnRnjjd0iRV83XGpSPvwOa6-IPhhphGWgMNr4atlQzYHq4z3NBMMj9l8LnSOWO6KbUpTuqeQniO_YSQ_TbzjC-3cAEBjB7MpjSuBLexv3JygnpYiWmOJnUoojH3pezGNoNePtshsEllelcMa1_1c1cuJ2stH59HcTgB0u6-cpYqupeHqZB9Bn6U-eVjV1Ut-8LkzkTZjuGmt4YZZdJ-nZrkgsDkcpEFKfmupYDv8_9y69zOQaFXQ8v90KB2DawNWSEDRbAx-EFfu3rIsA3Hz2a9w-wVQQ8PD0C94kn57y4iyYbZDCu9Pal8V27J8eyUCqMh1kYlBkinuat3a2zKjT6bL6Tds6TkLUuzefO6DoPUQGTBZK8ZYi7QotUGI8xYzg6T26vDFQcgaQngSD0ZhZaKeQXdvRI_qjEZqg5Rt1VYZlJF42cinJD0N5blYewxy44Ps5oIAkR8iGjAgVL3KI_LsThWaCEKxTM0ScVGdYoh0vuSdIpAKVQVX_qfC8D0" }
    let(:master_key) { [1049027610,743989201,1864038849,230624922] }
    let(:privk) { harness.decrypt_base64_to_str(privk_encoded, master_key) }
    let(:rsa_private_key) { harness.decompose_rsa_private_key(privk) }
    let(:csid_encoded) { "CABTMUpwxe-OSvX_AhWxDzNu-fvisC9oRNxV97EjmBDLmLvyrEkdWRy4jAxQBOEFiqTe8bvH5EJ_HIxg_reA83kFB8UkHp359CPIceDwrTfS1pm3_onh7rWOdanzTXdixqiDRWIPo5dEfsIJixMIXtlBONla8TlTpc6sQ5NsysqMNYBaHD-5Npqj01s-pjkfSVwrtGSVU_b0JlT8acBemb8cukeXYSXaVf6ILgnBGkFYNyzSN5wmDDOU8tySoyKTtaPV9QDym0CrrxeNCYZPeawQQ4C85_dmJTJwSDyUu3ApocY2LPMYvRzo2CEP80eLuLHTSSp8O9_LMi7MrSJxCM9m" }

    subject { harness.decrypt_session_id(csid_encoded,rsa_private_key) }
    let(:expected_sid) { "1au8GQLcKSCkswqio-0PHmFNdXZjYU1vZFhjr1rVWm_USjjSvFhQZbVfDA" }
    it { should eql(expected_sid) }

  end

  describe "#decompose_file_key" do
    # expectation generation in javascript:
    # dl_key = [1281139164, 1127317712, 263279788, 1988157168, 402822759, 1958040625, 716219392, 465402751]
    # expected_key = [dl_key[0]^dl_key[4],dl_key[1]^dl_key[5],dl_key[2]^dl_key[6],dl_key[3]^dl_key[7]]
    # => [1415460795, 931452129, 620884140, 1832756623]
    subject { harness.decompose_file_key(key) }
    [
      {
        key: [1281139164, 1127317712, 263279788, 1988157168, 402822759, 1958040625, 716219392, 465402751],
        expected_key: [1415460795, 931452129, 620884140, 1832756623]
      }
    ].each do |expectations|
      context "given #{expectations[:key]}" do
        let(:key) { expectations[:key] }
        it { should eql(expectations[:expected_key])}
      end
    end
  end

  describe "#decrypt_file_attributes" do
    subject { harness.decrypt_file_attributes(attributes,key) }
    {
      'simple_folder' => {
        f: { 't' => 1, 'a' => "US0wKXcni_p8dnqRvhR_Otafji3ioNJ5IsgSHB5zhOw" },
        key: [1479379715, 408676944, 1375748016, 1932394997],
        expected_attributes: {"n"=>"Research"}
      },
      'simple_file' => {
        f: { 't' => 0, 'a' => "n4CazRegf4aLA4BNrdoEsqRLGLQ244NjJUJi53Zz-J4" },
        key: [1281139164, 1127317712, 263279788, 1988157168, 402822759, 1958040625, 716219392, 465402751],
        expected_attributes: {"n"=>"mega.png"}
      }
    }.each do |test_name,expectations|
      context test_name do
        let(:f) { expectations[:f] }
        let(:attributes) { f['a'] }
        let(:key) { f['t'] == 0 ? harness.decompose_file_key(expectations[:key]) : expectations[:key] }
        it { should eql(expectations[:expected_attributes])}
      end
    end
  end

  describe "#get_chunks" do
    subject { harness.get_chunks(size) }
    {
      122000   => [[0, 122000]],
      332000   => [[0, 131072], [131072, 200928]],
      500000   => [[0, 131072], [131072, 262144], [393216, 106784]],
      800000   => [[0, 131072], [131072, 262144], [393216, 393216], [786432, 13568]],
      1800000  => [[0, 131072], [131072, 262144], [393216, 393216], [786432, 524288], [1310720, 489280]],
      2000000  => [[0, 131072], [131072, 262144], [393216, 393216], [786432, 524288], [1310720, 655360], [1966080, 33920]],
      2800000  => [[0, 131072], [131072, 262144], [393216, 393216], [786432, 524288], [1310720, 655360], [1966080, 786432], [2752512, 47488]],
      3800000  => [[0, 131072], [131072, 262144], [393216, 393216], [786432, 524288], [1310720, 655360], [1966080, 786432], [2752512, 917504], [3670016, 129984]],
      4800000  => [[0, 131072], [131072, 262144], [393216, 393216], [786432, 524288], [1310720, 655360], [1966080, 786432], [2752512, 917504], [3670016, 1048576], [4718592, 81408]],
      20800000 => [[0, 131072], [131072, 262144], [393216, 393216], [786432, 524288], [1310720, 655360], [1966080, 786432], [2752512, 917504], [3670016, 1048576], [4718592, 1048576], [5767168, 1048576], [6815744, 1048576], [7864320, 1048576], [8912896, 1048576], [9961472, 1048576], [11010048, 1048576], [12058624, 1048576], [13107200, 1048576], [14155776, 1048576], [15204352, 1048576], [16252928, 1048576], [17301504, 1048576], [18350080, 1048576], [19398656, 1048576], [20447232, 352768]],
    }.each do |size,chunks|
      context "when size=#{size}" do
        let(:size) { size }
        let(:expected) { chunks }
        it { should eql(chunks) }
      end
    end
  end

  describe "#calculate_chunk_mac" do
    subject { harness.calculate_chunk_mac(chunk,decomposed_key,iv) }
    [
      {
        chunk_b64:      'Re_JkMdeElC-EdjpC0Aoxw9k6mymXoJq5Deqgx9a2Vpj8sX6l34B',
        decomposed_key: [1455434630,1271130048,979342435,1808341711],
        iv:             [758940180,1555777008,0,0],
        expected_mac:   [2029949810, 584234195, 3282227752, 2170965113]
      }
    ].each do |options|
      context "when chunk_b64 = #{options[:chunk_b64]}" do
        let(:chunk)          { harness.base64urldecode(options[:chunk_b64]) }
        let(:decomposed_key) { options[:decomposed_key] }
        let(:iv)             { options[:iv] }
        it { should eql(options[:expected_mac]) }
      end
    end
  end

end
