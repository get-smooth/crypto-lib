import{IndividualPubKey_array, psign, partial_sig_agg, schnorr_verify, sha256, tagged_hashBTC, prefix_msg, nonce_gen_internal, nonce_hash, nonce_agg, hash_keys, key_agg_coeff, int_from_bytes, key_agg, nonce_gen} from './bip327.mjs'

import { randomBytes } from 'crypto'; // Use Node.js's crypto module
import { secp256k1 } from '@noble/curves/secp256k1'; // ESM and Common.js



/********************************************************************************************/
/* SESSION EXAMPLE*/   
/********************************************************************************************/
function test_noncegen(){
  
    console.log("/*************************** ");
    console.log("Test nonce_gen_internal:");
  
    //extracted from https://github.com/bitcoin/bips/blob/master/bip-0327/vectors/nonce_gen_vectors.json
    const     rand= [
        "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F",
        "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F",
        "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F",
        "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"
      ];
  
      const sk= [
        "0202020202020202020202020202020202020202020202020202020202020202",
        "0202020202020202020202020202020202020202020202020202020202020202",
        "0202020202020202020202020202020202020202020202020202020202020202",
        ""
      ];
  
      const pk= [
        "024D4B6CD1361032CA9BD2AEB9D900AA4D45D9EAD80AC9423374C451A7254D0766",
        "024D4B6CD1361032CA9BD2AEB9D900AA4D45D9EAD80AC9423374C451A7254D0766",
        "024D4B6CD1361032CA9BD2AEB9D900AA4D45D9EAD80AC9423374C451A7254D0766",
        "02F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9"
      ];
  
      const 
      aggpk= [
        "0707070707070707070707070707070707070707070707070707070707070707",
        "0707070707070707070707070707070707070707070707070707070707070707",
        "0707070707070707070707070707070707070707070707070707070707070707",
        ""
      ];
  
      const msg= [
        "0101010101010101010101010101010101010101010101010101010101010101",
        "",
        "2626262626262626262626262626262626262626262626262626262626262626262626262626",
         ""
      ];
  
      const extra_in= [
        "0808080808080808080808080808080808080808080808080808080808080808",
        "0808080808080808080808080808080808080808080808080808080808080808",
        "0808080808080808080808080808080808080808080808080808080808080808",
         ""
      ];
  
      const expected_secnonce= [
        "B114E502BEAA4E301DD08A50264172C84E41650E6CB726B410C0694D59EFFB6495B5CAF28D045B973D63E3C99A44B807BDE375FD6CB39E46DC4A511708D0E9D2024D4B6CD1361032CA9BD2AEB9D900AA4D45D9EAD80AC9423374C451A7254D0766",
        "E862B068500320088138468D47E0E6F147E01B6024244AE45EAC40ACE5929B9F0789E051170B9E705D0B9EB49049A323BBBBB206D8E05C19F46C6228742AA7A9024D4B6CD1361032CA9BD2AEB9D900AA4D45D9EAD80AC9423374C451A7254D0766",
        "3221975ACBDEA6820EABF02A02B7F27D3A8EF68EE42787B88CBEFD9AA06AF3632EE85B1A61D8EF31126D4663A00DD96E9D1D4959E72D70FE5EBB6E7696EBA66F024D4B6CD1361032CA9BD2AEB9D900AA4D45D9EAD80AC9423374C451A7254D0766",
        "89BDD787D0284E5E4D5FC572E49E316BAB7E21E3B1830DE37DFE80156FA41A6D0B17AE8D024C53679699A6FD7944D9C4A366B514BAF43088E0708B1023DD289702F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9"
      ];
  
      const expected_pubnonce= [
        "02F7BE7089E8376EB355272368766B17E88E7DB72047D05E56AA881EA52B3B35DF02C29C8046FDD0DED4C7E55869137200FBDBFE2EB654267B6D7013602CAED3115A",
        "023034FA5E2679F01EE66E12225882A7A48CC66719B1B9D3B6C4DBD743EFEDA2C503F3FD6F01EB3A8E9CB315D73F1F3D287CAFBB44AB321153C6287F407600205109",
        "02E5BBC21C69270F59BD634FCBFA281BE9D76601295345112C58954625BF23793A021307511C79F95D38ACACFF1B4DA98228B77E65AA216AD075E9673286EFB4EAF3",
        "02C96E7CB1E8AA5DAC64D872947914198F607D90ECDE5200DE52978AD5DED63C000299EC5117C2D29EDEE8A2092587C3909BE694D5CFF0667D6C02EA4059F7CD9786"
      ];
  
    for( var i=0;i<1;i++)
    { 
      let i_rand=Buffer.from(rand[i],'hex');
      console.log("rand noncegen=", i_rand);
      let i_pk=Buffer.from(pk[i],'hex');
      let i_sk=Buffer.from(sk[i],'hex');
      
      let i_aggpk=Buffer.from(aggpk[i],'hex');
      let i_extra=Buffer.from(extra_in[i],'hex');
      let i_msg=Buffer.from(msg[i],'hex');
  
      let res=nonce_hash(i_rand, i_pk,  i_aggpk,  0, prefix_msg(i_msg), i_extra);
      res=res.equals(Buffer.from("bf2dca60c7ca80ffe6bf4e7c75982611f24ad6946cc8be6f0eebe67d186799ca", 'hex'));
      if(res==false) return false;
  
      res=nonce_gen_internal(i_rand, i_sk, i_pk, i_aggpk, i_msg, i_extra);
     

      if((res[0]).equals(Buffer.from(expected_secnonce[i],'hex'))==false) return false;
      if((res[1]).equals(Buffer.from(expected_pubnonce[i],'hex'))==false) return false;
  
    }
    
    console.log("\n result:", true );
  
    return true;
  }
  
function test_tagged_hashBTC(){
    console.log("/*************************** JAVASCRIPT BIP 327 TESTS ********************************/" );
  
    console.log("/*************************** ");
    
    console.log("Test tagged_hashBTC:");
  
    const tag = "BIP0340/challenge";
    const tagHash = sha256(Buffer.from(tag, 'utf-8'));
    const message = Buffer.from("abc", 'utf-8');
    const result = tagged_hashBTC(tag, message);
    const expected = Buffer.from("770a5b7e7c304bbcc3ea107343ff951dd404312ef418db0c3b94e2ebfbb50087",'hex');
  
    console.log("message ", message);  
    console.log("Resulting hash", result);
    console.log("expected hash", expected);
    
    console.log("\n result:", result.equals(expected) )
    return (result.equals(expected));
  }
  
function test_nonceagg(){
  console.log("/*************************** ");
  console.log("Test nonce_agg:");


  //partial public nonces before aggregation  
  let pnonces= [
        "020151C80F435648DF67A22B749CD798CE54E0321D034B92B709B567D60A42E66603BA47FBC1834437B3212E89A84D8425E7BF12E0245D98262268EBDCB385D50641",
        "03FF406FFD8ADB9CD29877E4985014F66A59F6CD01C0E88CAA8E5F3166B1F676A60248C264CDD57D3C24D79990B0F865674EB62A0F9018277A95011B41BFC193B833",
        "020151C80F435648DF67A22B749CD798CE54E0321D034B92B709B567D60A42E6660279BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798",
        "03FF406FFD8ADB9CD29877E4985014F66A59F6CD01C0E88CAA8E5F3166B1F676A60379BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798" 
  ];  
  
  let expected_agg1="035FE1873B4F2967F52FEA4A06AD5A8ECCBE9D0FD73068012C894E2E87CCB5804B024725377345BDE0E9C33AF3C43C0A29A9249F2F2956FA8CFEB55C8573D0262DC8";
  let expected_agg2="035FE1873B4F2967F52FEA4A06AD5A8ECCBE9D0FD73068012C894E2E87CCB5804B000000000000000000000000000000000000000000000000000000000000000000";


  let res=nonce_agg([pnonces[0], pnonces[1]]);


  console.log("res",res);
  console.log("expected",expected_agg1);

  console.log(res.equals(Buffer.from(expected_agg1,'hex')));
  res=nonce_agg([pnonces[2], pnonces[3]]);

  console.log(res.equals(Buffer.from(expected_agg2,'hex')));
  return 1;
  console.log("res",res);
  console.log("expected",expected_agg2);

}

function test_keyaggcoeff(){
    console.log("/*************************** ");
    console.log("Test key_agg:");


    let pubkeys=[
        Buffer.from("02F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9",'hex'),
        Buffer.from("03DFF1D77F2A671C5F36183726DB2341BE58FEAE1DA2DECED843240F7B502BA659",'hex'),
        Buffer.from("023590A94E768F8E1815C2F24B4D80A8E3149316C3518CE7B7AD338368D038CA66",'hex')
    ];

    let res=hash_keys(pubkeys);
    let expected_h="9d3ba89d01849c97649989f2a441f701be800aaa15d957e687d4f56479bc49b9";

    console.log("hashkeys", res, expected_h);
    res=key_agg_coeff(pubkeys, pubkeys[0]);
    let expected= int_from_bytes(Buffer.from("ad0537c883813849e3b95ce5db1d45eb25cc5fae197c4e8759719065932aa183",'hex'));

    console.log("key agg coeff 0", res.toString(16), expected.toString(16));//test first coefficient is correct
    
    console.log("test 1:", expected==res);
   
    expected=Buffer.from("90539EEDE565F5D054F32CC0C220126889ED1E5D193BAF15AEF344FE59D4610C",'hex');

    let aggpk=(key_agg(pubkeys)[0]).slice(1,33);
    console.log("test 2::", Buffer.from(aggpk).equals(expected));//check key aggregation is correct

}


function test_schnorrverify(){
  console.log("/*************************** ");
  console.log("Test chnorr_verify:");
let msg=  Buffer.from("28d5dd7459fc54ff02304280ce9bcc54a29cf0e5d72cd4ccafe961a1cfe8a8d3",'hex');
let aggpk=Buffer.from("23189cc577a55b5ba8016136947cb0a1e97567d332cc993e9d108010708f10c0",'hex');
let sig=Buffer.from("61074a45b0030ff5b7280dd094bf06c361adc0394a9bd17756db7bc9aa5983536c5b2ebc4404cf1f04e71c3795484fe83aabc48845a56f796d7c816a67601256",'hex');

//0x61074a45b0030ff5b7280dd094bf06c361adc0394a9bd17756db7bc9aa59835323189cc577a55b5ba8016136947cb0a1e97567d332cc993e9d108010708f10c028d5dd7459fc54ff02304280ce9bcc54a29cf0e5d72cd4ccafe961a1cfe8a8d3
//e=0x833cad5d5e04b2edc3fac1cba4b921c6bf4404c0c6dd40af44be6395e53b2504
 let res=schnorr_verify(msg, aggpk, sig);

 console.log("", res);
}

//todo as comeback, sign_verify.json
function test_partialsig_notweak(){
  console.log("/*************************** ");
  console.log("Partial sig no tweak:");

  const pubkeys= [
        Buffer.from("03935F972DA013F80AE011890FA89B67A27B7BE6CCB24D3274D18B2D4067F261A9", 'hex'),
        Buffer.from("02F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9", 'hex'),
        Buffer.from("02DFF1D77F2A671C5F36183726DB2341BE58FEAE1DA2DECED843240F7B502BA661", 'hex')
  ];

  const secnonce=Buffer.from(
  "508B81A611F100A6B2B6B29656590898AF488BCF2E1F55CF22E5CFB84421FE61FA27FD49B1D50085B481285E1CA205D55C82CC1B31FF5CD54A489829355901F703935F972DA013F80AE011890FA89B67A27B7BE6CCB24D3274D18B2D4067F261A9"
  , 'hex');

  const sk=Buffer.from("7FB9E0E687ADA1EEBF7ECFE2F21E73EBDB51A7D450948DFE8D76D7F2D1007671", 'hex');
  const aggnonce=Buffer.from("028465FCF0BBDBCF443AABCCE533D42B4B5A10966AC09A49655E8C42DAAB8FCD61037496A3CC86926D452CAFCFD55D25972CA1675D549310DE296BFF42F72EEEA8C9",'hex');
  const msg=Buffer.from("F95466D086770E689964664219266FE5ED215C92AE20BAB5C9D79ADDDDF3C0CF",'hex');

  //'aggnonce','pubkeys', 'tweaks', 'is_xonly','msg';
  const session_ctx=[aggnonce, pubkeys, [], [], msg];
  const expected=Buffer.from("012ABBCB52B3016AC03AD82395A1A415C48B93DEF78718E62A7A90052FE224FB", 'hex');

  let res= psign(secnonce, sk, session_ctx);

  console.log("res=", Buffer.from(res));

  console.log("expected=", expected);

  console.log( Buffer.from(res).equals(expected));

}

//valid test case 1 from https://github.com/bitcoin/bips/blob/master/bip-0327/vectors/sig_agg_vectors.json
function test_sigagg_notweak(){
  console.log("/*************************** ");
  console.log("Test signature aggregation without tweak:");


  const pubkeys=[Buffer.from("03935F972DA013F80AE011890FA89B67A27B7BE6CCB24D3274D18B2D4067F261A9", 'hex'),
        Buffer.from("02D2DC6F5DF7C56ACF38C7FA0AE7A759AE30E19B37359DFDE015872324C7EF6E05", 'hex')];

  const tweaks=[];
  const msg=Buffer.from("599C67EA410D005B9DA90817CF03ED3B1C868E4DA4EDF00A5880B0082C237869", 'hex');

  const psigs=[Buffer.from("B15D2CD3C3D22B04DAE438CE653F6B4ECF042F42CFDED7C41B64AAF9B4AF53FB", 'hex'),
        Buffer.from("6193D6AC61B354E9105BBDC8937A3454A6D705B6D57322A5A472A02CE99FCB64", 'hex')];
  
  const aggnonce=Buffer.from("0341432722C5CD0268D829C702CF0D1CBCE57033EED201FD335191385227C3210C03D377F2D258B64AADC0E16F26462323D701D286046A2EA93365656AFD9875982B", 'hex');
  const expected="041DA22223CE65C92C9A0D6C2CAC828AAF1EEE56304FEC371DDF91EBB2B9EF0912F1038025857FEDEB3FF696F8B99FA4BB2C5812F6095A2E0004EC99CE18DE1E";
  
  //session context: 'aggnonce','pubkeys', 'tweaks', 'is_xonly','msg
  const session_context=[aggnonce, pubkeys, tweaks, [], msg ];
  
  let res=partial_sig_agg(psigs, session_context);
  console.log("res=", res.toString('hex'));

  let aggpkX=key_agg(pubkeys)[0].slice(1,33);
  let vrf=schnorr_verify(msg, aggpkX, res);
  
  console.log("schnorr verify=", vrf);
  
}


//valid test case 3, https://github.com/bitcoin/bips/blob/master/bip-0327/vectors/sig_agg_vectors.json
function test_partialsig_withtweak_1(){
  const msg=Buffer.from("599C67EA410D005B9DA90817CF03ED3B1C868E4DA4EDF00A5880B0082C237869", 'hex');


  const aggnonce=Buffer.from("0208C5C438C710F4F96A61E9FF3C37758814B8C3AE12BFEA0ED2C87FF6954FF186020B1816EA104B4FCA2D304D733E0E19CEAD51303FF6420BFD222335CAA402916D", 'hex');
  
  const pubkeys=[Buffer.from("03935F972DA013F80AE011890FA89B67A27B7BE6CCB24D3274D18B2D4067F261A9", 'hex'),
    Buffer.from("03C7FB101D97FF930ACD0C6760852EF64E69083DE0B06AC6335724754BB4B0522C", 'hex')];

    const tweaks=[Buffer.from("B511DA492182A91B0FFB9A98020D55F260AE86D7ECBD0399C7383D59A5F2AF7C", 'hex')];

    const psigs=[Buffer.from("4F5AEE41510848A6447DCD1BBC78457EF69024944C87F40250D3EF2C25D33EFE", 'hex'),
      Buffer.from("DDEF427BBB847CC027BEFF4EDB01038148917832253EBC355FC33F4A8E2FCCE4", 'hex')];

 const expected="5C558E1DCADE86DA0B2F02626A512E30A22CF5255CAEA7EE32C38E9A71A0E9148BA6C0E6EC7683B64220F0298696F1B878CD47B107B81F7188812D593971E0CC";
 
 const session_context=[aggnonce, pubkeys, tweaks, [false], msg ];
  
 
 let res=partial_sig_agg(psigs, session_context);
 console.log("res=", res.toString('hex'));
}


//valid test case 3, https://github.com/bitcoin/bips/blob/master/bip-0327/vectors/sig_agg_vectors.json
function test_partialsig_withtweak_2(){
  const msg=Buffer.from("599C67EA410D005B9DA90817CF03ED3B1C868E4DA4EDF00A5880B0082C237869", 'hex');


  const aggnonce=Buffer.from("02B5AD07AFCD99B6D92CB433FBD2A28FDEB98EAE2EB09B6014EF0F8197CD58403302E8616910F9293CF692C49F351DB86B25E352901F0E237BAFDA11F1C1CEF29FFD", 'hex');
  
  const pubkeys=[Buffer.from("03935F972DA013F80AE011890FA89B67A27B7BE6CCB24D3274D18B2D4067F261A9", 'hex'),
  Buffer.from("02352433B21E7E05D3B452B81CAE566E06D2E003ECE16D1074AABA4289E0E3D581", 'hex')];

  const tweaks=[Buffer.from("B511DA492182A91B0FFB9A98020D55F260AE86D7ECBD0399C7383D59A5F2AF7C", 'hex'),
        Buffer.from("A815FE049EE3C5AAB66310477FBC8BCCCAC2F3395F59F921C364ACD78A2F48DC", 'hex'),
        Buffer.from("75448A87274B056468B977BE06EB1E9F657577B7320B0A3376EA51FD420D18A8", 'hex')
  ];

  const psigs=[Buffer.from("97B890A26C981DA8102D3BC294159D171D72810FDF7C6A691DEF02F0F7AF3FDC", 'hex'),
  Buffer.from("53FA9E08BA5243CBCB0D797C5EE83BC6728E539EB76C2D0BF0F971EE4E909971", 'hex')];

 const expected=Buffer.from("839B08820B681DBA8DAF4CC7B104E8F2638F9388F8D7A555DC17B6E6971D7426CE07BF6AB01F1DB50E4E33719295F4094572B79868E440FB3DEFD3FAC1DB589E", 'hex');
 
 const session_context=[aggnonce, pubkeys, tweaks, [true, false, true], msg ];
  
 
 let res=partial_sig_agg(psigs, session_context);
 console.log("res=", res.toString('hex'), res);
 console.log(expected.equals( res));
 
}


//a full session generated using reference.py
function unitary_fullsession(){
  console.log("/*************************** ");
  console.log("Full session, compare with python generated input:");

  const msg=Buffer.from("e0601e248a22338872c707bdd7627195e4ea56ac9ad4c4c900560b8f39ad1dab", 'hex');

  const sk1=Buffer.from("a35de7d4e30dc61b6eadd376c2e62072f2be817b6468d3021e2a443762d396bd", 'hex');
  const pubK1=IndividualPubKey_array(sk1);
  const sk2=Buffer.from("cbdee7c9611746164315d955f75234778dddaa3e50f220283f3deb0dafe20dab", 'hex');
  const pubK2=IndividualPubKey_array(sk2);

  const pubkeys=[pubK1, pubK2];
  
  let aggpk = key_agg(pubkeys)[0];//here aggpk is a 33 bytes compressed public key
  let x_aggpk=aggpk.slice(1,33);//x-only version for noncegen

  console.log("Aggregated Pubkey:", aggpk);

  const rand1=Buffer.from("0cea0923038e6fa408e728539dca5accb1f9d433150f0d2680607afe831955bd", 'hex');
  const rand2=Buffer.from("cb555086ba1e545c0fef5bc4c35bb6e1fec90a482a4bfc20e10896c372e78661", 'hex');

  const nonce1=nonce_gen_internal(rand1, sk1, pubK1, x_aggpk, msg, Buffer.from("00000000", 'hex'));
  const nonce2=nonce_gen_internal(rand2, sk2, pubK2, x_aggpk, msg, Buffer.from("00000000", 'hex'));

  let aggnonce = nonce_agg([nonce1[1].toString('hex'), nonce2[1].toString('hex')]);
  console.log("aggnonce is =", aggnonce);


    //'aggnonce','pubkeys', 'tweaks', 'is_xonly','msg';
    const session_ctx=[aggnonce, pubkeys, [], [], msg];

    let p1=psign(nonce1[0], sk1, session_ctx);
    console.log("p1=",p1);


    let p2=psign(nonce2[0], sk2, session_ctx);
    console.log("p2=",p2);
    
    let psigs=[p1,p2];

    let res=partial_sig_agg(psigs, session_ctx);
    console.log("res=", res, res.length);

    let check=schnorr_verify(msg, x_aggpk, res);

    console.log("check=", check);
}


//illustrate a session without tweak, generates a new vector at each iteration
function test_sign_and_verify_random_notweak(){
  console.log("/*************************** ");
  console.log("Test full session, random generation of input:");


    const sk1=secp256k1.utils.randomPrivateKey();//this provides a 32 bytes array
    const sk2=secp256k1.utils.randomPrivateKey();
    
    console.log("sk1=",sk1 );
    console.log("sk2=",sk2 );
    let seckeys=[sk1, sk2];

    const pubK1=IndividualPubKey_array(sk1);
    const pubK2=IndividualPubKey_array(sk2);

    console.log("pubK1=",pubK1 );
    console.log("pubK2=",pubK2 );
    
    const pubkeys=[pubK1, pubK2];

    let aggpk = key_agg(pubkeys)[0];//here aggpk is a 33 bytes compressed public key
    let x_aggpk=aggpk.slice(1,33);//x-only version for noncegen

    console.log("Aggregated Pubkey:", aggpk);

    let msg=Buffer.from(randomBytes(32));
    let i=0;

    //diversification chain
    const extra_in= Buffer.from(randomBytes(32));
    
    let nonce1= nonce_gen(seckeys[0], pubkeys[0], x_aggpk,  msg, extra_in);
    let nonce2= nonce_gen(seckeys[1], pubkeys[1], x_aggpk,  msg, extra_in);

    //aggregation of public nonces
    let aggnonce = nonce_agg([nonce1[1].toString('hex'), nonce2[1].toString('hex')]);
    console.log("aggnonce=", aggnonce);

    //'aggnonce','pubkeys', 'tweaks', 'is_xonly','msg';
    const session_ctx=[aggnonce, pubkeys, [], [], msg];

    let p1=psign(nonce1[0], seckeys[0], session_ctx);
    console.log("p1=",p1);

    let p2=psign(nonce2[0], seckeys[1], session_ctx);
    console.log("p2=",p2);
    
    let psigs=[p1,p2];

    let res=partial_sig_agg(psigs, session_ctx);
    console.log("res=", res, res.length);

    let check=schnorr_verify(msg, x_aggpk, res);

    console.log("check=", check);
}


  (async () => {
    
  // Example usage:
  /*
  test_tagged_hashBTC(); //hash is ok
  test_noncegen(); //nonce generation is ok
  test_nonceagg();//nonce aggregation is ok
  
  
  test_partialsig_notweak();//partial signature is ok
  
  test_sigagg_notweak();//signature aggregation is ok
 */
  test_keyaggcoeff();//key aggregation is ok
  unitary_fullsession();
  test_sign_and_verify_random_notweak();
 
 

  })();
  
  