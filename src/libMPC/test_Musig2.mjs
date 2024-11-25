/********************************************************************************************/
/*
/*     ___                _   _       ___               _         _    _ _    
/*    / __|_ __  ___  ___| |_| |_    / __|_ _ _  _ _ __| |_ ___  | |  (_) |__ 
/*    \__ \ '  \/ _ \/ _ \  _| ' \  | (__| '_| || | '_ \  _/ _ \ | |__| | '_ \
/*   |___/_|_|_\___/\___/\__|_||_|  \___|_|  \_, | .__/\__\___/ |____|_|_.__/
/*                                         |__/|_|           
/*              
/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smooth CryptoLib) project
/* License: This software is licensed under MIT License                                        
/********************************************************************************************/


import{SCL_ecc} from './SCL_ecc.mjs';
import{SCL_Musig2} from './SCL_Musig2.mjs';


function test_compression(){
    console.log("/*************************** ");
    console.log("Test compression/decompression");

    const curve = 'ed25519';
    const signer = new SCL_ecc(curve);


    let Point=signer.GetBase();

    let cP=signer.PointCompress(Point);
    let rP=signer.PointDecompress(cP);

    console.log(":", rP.equals(Point));
}    

function test_keyaggcoeff(){
    const curve = 'secp256k1';
    const signer = new SCL_Musig2(curve);

    console.log("/*************************** ");
    console.log("Test key_agg:");


    let pubkeys=[
        Buffer.from("02F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9",'hex'),
        Buffer.from("03DFF1D77F2A671C5F36183726DB2341BE58FEAE1DA2DECED843240F7B502BA659",'hex'),
        Buffer.from("023590A94E768F8E1815C2F24B4D80A8E3149316C3518CE7B7AD338368D038CA66",'hex')
    ];

    let expected=Buffer.from("0290539EEDE565F5D054F32CC0C220126889ED1E5D193BAF15AEF344FE59D4610C",'hex');

    let aggpk=(signer.Key_agg(pubkeys)[0])
    console.log(":",  Buffer.from(aggpk).equals(expected));//check key aggregation is correct

    return Buffer.from(aggpk).equals(expected);
}


function test_noncegen(){
    const curve = 'secp256k1';
    const signer = new SCL_Musig2(curve);

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
  
      let res=signer.Nonce_hash(i_rand, i_pk,  i_aggpk,  0, signer.prefix_msg(i_msg), i_extra);
      res=res.equals(Buffer.from("bf2dca60c7ca80ffe6bf4e7c75982611f24ad6946cc8be6f0eebe67d186799ca", 'hex'));
      if(res==false) return false;
  
      res=signer.Nonce_gen_internal(i_rand, i_sk, i_pk, i_aggpk, i_msg, i_extra);
     

      if((res[0]).equals(Buffer.from(expected_secnonce[i],'hex'))==false) return false;
      if((res[1]).equals(Buffer.from(expected_pubnonce[i],'hex'))==false) return false;
  
    }
    
    console.log("\n result:", true );
  
    return true;
  }

function test_nonceagg(){
    const curve = 'secp256k1';
    const signer = new SCL_Musig2(curve);
    
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
  
  
    let res=signer.Nonce_agg([pnonces[0], pnonces[1]]);
  
  
  
    console.log(res.equals(Buffer.from(expected_agg1,'hex')));
    res=signer.Nonce_agg([pnonces[2], pnonces[3]]);
  
    console.log(res.equals(Buffer.from(expected_agg2,'hex')));

  
  }


//valid test case 3, https://github.com/bitcoin/bips/blob/master/bip-0327/vectors/sig_agg_vectors.json
function test_partialsig_withtweak_1(){
    const curve = 'secp256k1';
    const signer = new SCL_Musig2(curve);
    
    console.log("/*************************** ");
    console.log("Test signature aggregation:");

    const msg=Buffer.from("599C67EA410D005B9DA90817CF03ED3B1C868E4DA4EDF00A5880B0082C237869", 'hex');
  
  
    const aggnonce=Buffer.from("0208C5C438C710F4F96A61E9FF3C37758814B8C3AE12BFEA0ED2C87FF6954FF186020B1816EA104B4FCA2D304D733E0E19CEAD51303FF6420BFD222335CAA402916D", 'hex');
    
    const pubkeys=[Buffer.from("03935F972DA013F80AE011890FA89B67A27B7BE6CCB24D3274D18B2D4067F261A9", 'hex'),
      Buffer.from("03C7FB101D97FF930ACD0C6760852EF64E69083DE0B06AC6335724754BB4B0522C", 'hex')];
  
      const tweaks=[Buffer.from("B511DA492182A91B0FFB9A98020D55F260AE86D7ECBD0399C7383D59A5F2AF7C", 'hex')];
  
      const psigs=[Buffer.from("4F5AEE41510848A6447DCD1BBC78457EF69024944C87F40250D3EF2C25D33EFE", 'hex'),
        Buffer.from("DDEF427BBB847CC027BEFF4EDB01038148917832253EBC355FC33F4A8E2FCCE4", 'hex')];
  
   const expected="5C558E1DCADE86DA0B2F02626A512E30A22CF5255CAEA7EE32C38E9A71A0E9148BA6C0E6EC7683B64220F0298696F1B878CD47B107B81F7188812D593971E0CC";
   
   const session_context=[aggnonce, pubkeys, tweaks, [false], msg ];
    
   
   let res=signer.Partial_sig_agg(psigs, session_context);
  
   console.log("", Buffer.from(expected,'hex').equals(res));
  }


//a full session generated using reference.py
function unitary_fullsession(){
    const curve = 'secp256k1';
    const signer = new SCL_Musig2(curve);

    console.log("/*************************** ");
    console.log("Full session, compare with python generated input:");
  
    const msg=Buffer.from("e0601e248a22338872c707bdd7627195e4ea56ac9ad4c4c900560b8f39ad1dab", 'hex');
  
    const sk1=Buffer.from("a35de7d4e30dc61b6eadd376c2e62072f2be817b6468d3021e2a443762d396bd", 'hex');
    const pubK1=signer.IndividualPubKey_array(sk1);
    const sk2=Buffer.from("cbdee7c9611746164315d955f75234778dddaa3e50f220283f3deb0dafe20dab", 'hex');
    const pubK2=signer.IndividualPubKey_array(sk2);
  
    const pubkeys=[pubK1, pubK2];
    
    let aggpk = signer.Key_agg(pubkeys)[0];//here aggpk is a 33 bytes compressed public key
    let x_aggpk=aggpk.slice(1,33);//x-only version for noncegen
  
    console.log("Aggregated Pubkey:", aggpk);
  
    const rand1=Buffer.from("0cea0923038e6fa408e728539dca5accb1f9d433150f0d2680607afe831955bd", 'hex');
    const rand2=Buffer.from("cb555086ba1e545c0fef5bc4c35bb6e1fec90a482a4bfc20e10896c372e78661", 'hex');
  
    const nonce1=signer.Nonce_gen_internal(rand1, sk1, pubK1, x_aggpk, msg, Buffer.from("00000000", 'hex'));
    const nonce2=signer.Nonce_gen_internal(rand2, sk2, pubK2, x_aggpk, msg, Buffer.from("00000000", 'hex'));
  
    let aggnonce = signer.Nonce_agg([nonce1[1].toString('hex'), nonce2[1].toString('hex')]);
    console.log("aggnonce is =", aggnonce);
  
  
      //'aggnonce','pubkeys', 'tweaks', 'is_xonly','msg';
      const session_ctx=[aggnonce, pubkeys, [], [], msg];
  
      let p1=signer.Psign(nonce1[0], sk1, session_ctx);
      console.log("p1=",p1);
  
  
      let p2=signer.Psign(nonce2[0], sk2, session_ctx);
      console.log("p2=",p2);
      
      let psigs=[p1,p2];
  
      let res=signer.Partial_sig_agg(psigs, session_ctx);
      console.log("res=", res, res.length);
  
      let check=signer.Schnorr_verify(msg, x_aggpk, res);
  
      console.log("check=", check);
  }

  
  
function test_schnorrverify(){
    const curve = 'secp256k1';
    const signer = new SCL_Musig2(curve);

  console.log("/*************************** ");
  console.log("Test Schnorr_verify:");
let msg=  Buffer.from("28d5dd7459fc54ff02304280ce9bcc54a29cf0e5d72cd4ccafe961a1cfe8a8d3",'hex');
let aggpk=Buffer.from("23189cc577a55b5ba8016136947cb0a1e97567d332cc993e9d108010708f10c0",'hex');
let sig=Buffer.from("61074a45b0030ff5b7280dd094bf06c361adc0394a9bd17756db7bc9aa5983536c5b2ebc4404cf1f04e71c3795484fe83aabc48845a56f796d7c816a67601256",'hex');

//0x61074a45b0030ff5b7280dd094bf06c361adc0394a9bd17756db7bc9aa59835323189cc577a55b5ba8016136947cb0a1e97567d332cc993e9d108010708f10c028d5dd7459fc54ff02304280ce9bcc54a29cf0e5d72cd4ccafe961a1cfe8a8d3
//e=0x833cad5d5e04b2edc3fac1cba4b921c6bf4404c0c6dd40af44be6395e53b2504
 let res=signer.Schnorr_verify(msg, aggpk, sig);

 console.log("", res);
}

(async () => {


    test_compression();
    test_keyaggcoeff();//key aggregation is ok
    test_noncegen();
    test_nonceagg();
    test_partialsig_withtweak_1();
    test_schnorrverify();
    unitary_fullsession();
})();