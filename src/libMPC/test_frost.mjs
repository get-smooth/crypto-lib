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

import {  ed25519 } from '@noble/curves/ed25519';
import{reverse, bytes_xor, int_from_bytes, int_to_bytes, tagged_hashBTC, taghash_rfc8032} from "./common.mjs";

import { secp256k1 } from '@noble/curves/secp256k1';
import { etc, utils, getPublicKey } from '@noble/secp256k1';
import{SCL_ecc} from './SCL_ecc.mjs';
import { randomBytes } from 'crypto'; // Use Node.js's crypto module
import { Field } from "@noble/curves/abstract/modular";

import { SCL_FROST, SCL_trustedKeyGen, Interpolate_group_pubkey } from './SCL_frost.mjs';


//random vector generation
function test_randomInterpolate_secret(Curvename){
 
console.log("/*************************** ");
console.log("Test lagrange interpolation on curve:", Curvename);

 let curve=new SCL_ecc(Curvename);
 let sk=curve.Get_Random_privateKey();

 let dealer=new SCL_trustedKeyGen( Curvename,sk, 12,4);

 console.log("Consistency secret/public shares:",dealer.Check_Shares());
 //erasing to prove Reed Solomon like recovery of missing shares
 dealer.secshares.pop();
 dealer.secshares.pop();

 let rec_secret=dealer.Interpolate_group_seckey(dealer.secshares);
 console.log("interpolating secret:", rec_secret==int_from_bytes(sk));


 let rec_public=Interpolate_group_pubkey(dealer.pubshares, dealer.ids, curve);
 
 console.log("interpolating public keys", Buffer.from(rec_public).equals(dealer.pubkey));
}

//same as Musig2 test, tested OK
function test_aggnonce(){
   
    let frost = new SCL_FROST('secp256k1');
    
    console.log("/*************************** ");
    console.log("Test nonce_agg:");

    let pnonces= [
        "020151C80F435648DF67A22B749CD798CE54E0321D034B92B709B567D60A42E66603BA47FBC1834437B3212E89A84D8425E7BF12E0245D98262268EBDCB385D50641",
        "03FF406FFD8ADB9CD29877E4985014F66A59F6CD01C0E88CAA8E5F3166B1F676A60248C264CDD57D3C24D79990B0F865674EB62A0F9018277A95011B41BFC193B833",
        "020151C80F435648DF67A22B749CD798CE54E0321D034B92B709B567D60A42E6660279BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798",
        "03FF406FFD8ADB9CD29877E4985014F66A59F6CD01C0E88CAA8E5F3166B1F676A60379BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798"
    ];
    let expected_agg1="035FE1873B4F2967F52FEA4A06AD5A8ECCBE9D0FD73068012C894E2E87CCB5804B024725377345BDE0E9C33AF3C43C0A29A9249F2F2956FA8CFEB55C8573D0262DC8";
    let expected_agg2="035FE1873B4F2967F52FEA4A06AD5A8ECCBE9D0FD73068012C894E2E87CCB5804B000000000000000000000000000000000000000000000000000000000000000000";
  

    let res=frost.Nonce_agg([pnonces[0], pnonces[1]]);
    console.log(res.equals(Buffer.from(expected_agg1,'hex')));


}

function test_noncegen()
{
    let frost = new SCL_FROST('secp256k1');
    
    console.log("/*************************** ");
    console.log("Test nonce_gen:");

    let rand_=Buffer.from("0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F",'hex');
    let secshare=Buffer.from("0202020202020202020202020202020202020202020202020202020202020202",'hex');;

    let pubshare=Buffer.from("024D4B6CD1361032CA9BD2AEB9D900AA4D45D9EAD80AC9423374C451A7254D0766",'hex');;

    let group_pk=Buffer.from("0707070707070707070707070707070707070707070707070707070707070707",'hex');;
    let msg=Buffer.from("0101010101010101010101010101010101010101010101010101010101010101",'hex');;

    let extra_in=Buffer.from("0808080808080808080808080808080808080808080808080808080808080808",'hex');;
    let expected_secnonce=Buffer.from("6135CE36209DB5E3E7B7A11ADE54D3028D3CFF089DA3C2EC7766921CC4FB3D1BBCD8A7035194A76F43D278C3CD541AEE014663A2251DDE34E8D900EDF1CAA3D9",'hex');
    let expected_pubnonce=Buffer.from("02A5671568FD7AEA35369FE4A32530FD0D0A23D125627BEA374D9FA5676F645A6103EC4E899B1DBEFC08C51F48E3AFA8503759E9ECD3DE674D3C93FD0D92E15E631A",'hex');

    let res=frost.Nonce_gen_internal(rand_, secshare, pubshare, group_pk, msg, extra_in);


    console.log(expected_secnonce.equals(Buffer.from(res[0].slice(0,64))));
    console.log(expected_pubnonce.equals(Buffer.from(res[1])));

}

//test signature agglomeration
function test_SigAgg(){

    let frost = new SCL_FROST('secp256k1');

    console.log("/*************************** ");
    console.log("Test Signature aggregation:");

let n= 5;
let min_participants=3;
let group_public_key="037940B3ED1FDC360252A6F48058C7B94276DFB6AA2B7D51706FB48326B19E7AE1";
let ids_all=[BigInt(1), BigInt(2), BigInt(3), BigInt(4), BigInt(5)];
let pubshares_all=[
        Buffer.from("02BB66437FCAA01292BFB4BB6F19D67818FE693215C36C4663857F1DC8AB8BF4FA",'hex'),
        Buffer.from("02C3250013C86AA9C3011CD40B2658CBC5B950DD21FFAA4EDE1BB66E18A063CED5",'hex'),
        Buffer.from("03259D7068335012C08C5D80E181969ED7FFA08F7973E3ED9C8C0BFF3EC03C223E",'hex'),
        Buffer.from("02A22971750242F6DA35B8DB0DFE74F38A3227118B296ADD2C65E324E2B7EB20AD",'hex'),
        Buffer.from("03541293535BB662F8294C4BEB7EA25F55FEAE86C6BAE0CEBD741EAAA28639A6E6",'hex')];

let pubnonces=[
       "021AD89905F193EC1CBED15CDD5F4F0E04FF187648390639C88AC291F2F88D407E02FD49462A942948DF6718EEE86FDD858B124375E6A034A4985D19EE95431E9E03",
        "03A0640E5746CC90EC3EF04F133AF1B79DE67011927A9BA1510B9254E9C8698062037209BB6915B573D2E6394032E508B8285DD498FE8A85971AAB01ACF0C785A56B",
        "02861EFD258C9099BEF14FA9B3B4E6229595D8200FC72D27F789D4CCC4352BB32B038496DA1C20DFE16D24D20F0374812347EE9CFF06928802C04A2D1B2D369F4628",
        "0398DD496FFE3C14D2DDFB5D9FD1189DB829301A83C45F2A1DDF07238529F75D1D0233E8FF18899A66276D27AE5CE28A5170EEAAC4F05DEACC8E7DB1C55F8985495F",
        "03C7B31E363526D04B5D31148EE6B042AF8CC7DFA922A42A69EB78B816D458D0B20257495EC72B1E59FB90A48B036FBD3D9AE4415C49B6171E108185124B99DE56AA"];
       

let tweaks=[
        "B511DA492182A91B0FFB9A98020D55F260AE86D7ECBD0399C7383D59A5F2AF7C",
        "A815FE049EE3C5AAB66310477FBC8BCCCAC2F3395F59F921C364ACD78A2F48DC",
        "75448A87274B056468B977BE06EB1E9F657577B7320B0A3376EA51FD420D18A8"
    ];

let msg=Buffer.from("599C67EA410D005B9DA90817CF03ED3B1C868E4DA4EDF00A5880B0082C237869",'hex');
let psigs_all=[
         Buffer.from("447D69D4E02693E3F6C04E198F34E89E17D65DC29C92E635E8BFB8D2908DCA6A",'hex'),
         Buffer.from("E7E02FDE0FA66D116C0DCF932F7976D611A4D0CF225087C2B8282153E461FA8B",'hex'),
         Buffer.from("E84B98E0B132F4049B061A949EF69E3DFBEB3E2712AEE2DEE0C5B6D517860339",'hex'),
         Buffer.from("714B7FCF4D3EA2F4BB2B22F786AEBF0C65E1A6E6FBEF04C39B60EAA1CA257CD5",'hex'),
         Buffer.from("DA815BBE9D06203D5ADD3AD5D3FE5F0D5405939EFD7EA3FED6DACA9E5449AD80",'hex'),
         Buffer.from("8E367AE4000EEEFCEF7F83DA1AC96181DC51BA0D83E0F834F67A0CFD487DBEF7",'hex'),
         Buffer.from("9CAB74D0FBCF14D89330D81C85482B8C720DC69899187F3A5432A5856609E92D",'hex'),
         Buffer.from("351F38F8B3126944362D9B3F0D83791CF3D623E746B84A58012DF4C9383909EC",'hex'),
         Buffer.from("B9ABA5EE2181EDE7A0D3D29DB147741F66B5A8EF3BB6C9CFD1FAD0D98E5A8A93",'hex'),
         Buffer.from("A2DF2C5ECB1141E0B55F47711BBDAE491F2F22D967FA1D9569200B7FB0754AD6",'hex'),
         Buffer.from("441DFF8E4E0E8368D21BD3DD70F151C7C581EC2B1931B8F041CC8C052FEBF046",'hex'),
         Buffer.from("DDC813A7AA07415634F2F6CC10984EF68216C75EA4F7A8E883DBA163C41CE2BA",'hex'),
         Buffer.from("2D64FC0371D08A7069997C1009814AF9C964DB64AEDB919AC229DA774AB09888",'hex'),
         Buffer.from("5F6481FC18E4CB223CB5BAB966165A1033349267702E7D75B5A0E5CACEA0E6A0",'hex'),
         Buffer.from("312170A9C271F67D09C8BE06A468106505CF6B7CD4DB1A40E02AF13213069EB0",'hex'),
         Buffer.from("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141",'hex')
];


let aggnonce=frost.Nonce_agg([pubnonces[0], pubnonces[1], pubnonces[2]]);
//console.log("aggnonce:", aggnonce);

//input session context: 'aggnonce', 'ids', 'pubkeys', 'tweaks', 'is_xonly','msg'

let ids=[ids_all[0], ids_all[1], ids_all[2]];
let psigs=[psigs_all[0], psigs_all[1], psigs_all[2]];
let pubshares=[pubshares_all[0], pubshares_all[1], pubshares_all[2]]

let session_ctx=[aggnonce, ids, pubshares, [], [], msg];
let res=frost.Partial_sig_agg(psigs, ids, session_ctx);
let expected=Buffer.from("8471BE6E49D0E43097DD32DA374039149F5D00165A8AD369AE86E362D13730DA14A93293A0FFF4F9FDD438415DA4FDB4B008B2EB730110600208D3E1EC0945AC",'hex');
console.log(expected.equals(res));
}

function test_partialSig(){
    let frost = new SCL_FROST('secp256k1');

    console.log("/*************************** ");
    console.log("Test Partial Signature:");

    let group_public_key="037940B3ED1FDC360252A6F48058C7B94276DFB6AA2B7D51706FB48326B19E7AE1";
    let secshare_p1=Buffer.from("81D0D40CDF044588167A987C14552954DB187AC5AD3B1CA40D7B03DCA32AFDFB",'hex');
    let ids_all=[BigInt(1), BigInt(2), BigInt(3), BigInt(4), BigInt(5)];

    let pubshares=[
        Buffer.from("02BB66437FCAA01292BFB4BB6F19D67818FE693215C36C4663857F1DC8AB8BF4FA",'hex'),
        Buffer.from("02C3250013C86AA9C3011CD40B2658CBC5B950DD21FFAA4EDE1BB66E18A063CED5",'hex'),
        Buffer.from("03259D7068335012C08C5D80E181969ED7FFA08F7973E3ED9C8C0BFF3EC03C223E",'hex')
    ];

    let secnonces_p1=Buffer.from("96DF27F46CB6E0399C7A02811F6A4D695BBD7174115477679E956658FF2E83D618E4F670DF3DEB215934E4F68D4EEC71055B87288947D75F6E1EA9037FF62173",'hex');

    let pubnonces=[
        Buffer.from("02FCDBEE416E4426FB4004BAB2B416164845DEC27337AD2B96184236D715965AB2039F71F389F6808DC6176F062F80531E13EA5BC2612B690FC284AE66C2CD859CE9",'hex'),
        Buffer.from("02D26EF7E09A4BC0A2CF295720C64BAD56A28EF50B6BECBD59AF6F3ADE6C2480C503D11B9993AE4C2D38EA2591287F7B744976F0F0B79104B96D6399507FC533E893",'hex'),
        Buffer.from("03C7E3D6456228347B658911BF612967F36C7791C24F9607ADB34E09F8CC1126D803D2C9C6E3D1A11463F8C2D57B145A814F5D44FD1A42F7A024140AC30D48EE0BEE",'hex')
    ];

    let aggnonce=Buffer.from("02047C99228CEA528AE200A82CBE4CD188BC67D58F537D1904A16B07FCDE07C3A6038708199DFA5BC5C41A0DD0FBD7D0620ADB4AC9991F7DB55A155CE9396AA80D1A",'hex');
    let ids=[BigInt(1), BigInt(2), BigInt(3)];
    let msg=Buffer.from("F95466D086770E689964664219266FE5ED215C92AE20BAB5C9D79ADDDDF3C0CF",'hex');
    //input session context: 'aggnonce', 'ids', 'pubkeys', 'tweaks', 'is_xonly','msg'
    let session_ctx=[aggnonce, ids, pubshares, [], [], msg];
    let res=frost.Psign(secnonces_p1, secshare_p1, BigInt(1), session_ctx);

    let expected=Buffer.from("DEDAA44E6DB7FF1B40D8CBAA44DF3F8C80BD7CEC6A21AE22F34ED7ABC59E2AEC",'hex');
   
    console.log("expected=", expected.equals(res));

}


function randomSubset(n, subsetSize) {
    if (subsetSize > n) {
        throw new Error("Subset size cannot be larger than n");
    }

    const subset = new Set();

    // Randomly select `subsetSize` unique numbers
    while (subset.size < subsetSize) {
        const randomNumber = Math.floor(Math.random() * n);
        subset.add(randomNumber); // Use a Set to avoid duplicates
    }

    // Convert to array and sort in increasing order
    return Array.from(subset).sort((a, b) => a - b);
}

//randomly generated full session
function test_random_fullsession(Curvename){

    console.log("/*************************** ");
    console.log("Test Full FROST session, random input on curve:", Curvename);

    let n=12;
    let k=4;

    console.log("----------Generate Keys:");
    let curve=new SCL_ecc(Curvename);
    let sk=curve.Get_Random_privateKey();
    let dealer=new SCL_trustedKeyGen( Curvename,sk, n,k);
    let frost=new SCL_FROST(Curvename);

    console.log("    Check key correctness:", dealer.Check_Shares());

   
   

    console.log("----------Signer Set:");
    let elements=randomSubset(n, k+1);
    console.log("set:", elements);
    let Ids = elements.map(index => dealer.ids[index]);
    console.log("ids:", Ids);
    let pubshares=elements.map(index => dealer.pubshares[index]);//pubshares as points

    //dealer provide shares to users:
    let b8_pubshares=elements.map(index => curve.PointCompress(dealer.pubshares[index]))
    let secshares=elements.map(index => dealer.secshares[index]);

    let group_pk=Interpolate_group_pubkey(pubshares, Ids, curve);
    let x_group_pk=curve.ForceXonly(group_pk);//x-only version for noncegen, allways 32

    console.log("    Interpolating public key from pubkey set", Buffer.from(group_pk).equals(dealer.pubkey));

    let rec_secret=dealer.Interpolate_group_seckey(secshares);
    console.log("    Interpolating secret key from seckey set:", rec_secret==int_from_bytes(dealer.sk));


    console.log("----------Generate message and nonces");

    const msg=Buffer.from(randomBytes(32));
    const extra_in= Buffer.from(randomBytes(32));

    let secnonces=[];
    let pubnonces=[];

    for(let i=0;i<k+1;i++){
        let nonce=frost.Nonce_gen( int_to_bytes(secshares[i][1],32), b8_pubshares[i], group_pk, msg, extra_in );
        secnonces.push(nonce[0]);
        pubnonces.push(nonce[1].toString('hex'));
    }
    //console.log("secnonces", secnonces,"pubnonces",  pubnonces);


    console.log("----------Aggnonce");
    let aggnonce=frost.Nonce_agg(pubnonces)
    console.log("aggnonce", aggnonce);

    //input session context: 'aggnonce', 'ids', 'pubkeys', 'tweaks', 'is_xonly','msg'
    let session_context=[aggnonce, Ids, b8_pubshares, [], [], msg];


    console.log("----------Psigs");
    let psigs=[];
    for(let i=0;i<k+1;i++){
        let psig=frost.Psign(secnonces[i], int_to_bytes(secshares[i][1],32), Ids[i], session_context);
        console.log("psig:", psig);
        psigs.push(psig);
    }


    console.log("----------Aggregation");
    let final_sig=frost.Partial_sig_agg(psigs, Ids, session_context);
    console.log("sig", final_sig);

    console.log("final verif:", frost.Schnorr_verify(msg, x_group_pk,final_sig ));
}


(async () => {
    test_randomInterpolate_secret('secp256k1');
    test_randomInterpolate_secret('ed25519');
    
    test_aggnonce();
    test_noncegen();
    test_partialSig();
    test_SigAgg();

    test_random_fullsession('secp256k1');

    test_random_fullsession('ed25519');

})();