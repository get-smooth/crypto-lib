#/********************************************************************************************/
#/*
#/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
#/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
#/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
#/*              
#/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
#/* License: This software is licensed under MIT License (and allways will)   
#/* Description: This library contains utils that provides OFFCHAIN computations, they are  provided as
#/* an helper for integration, test and fuzzing BUT SHALL NOT USED ONCHAIN for performances and security reasons                  
#/********************************************************************************************/
#// SPDX-License-Identifier: MIT


import json
import json

def parse_line(line):
    parts = line.strip().split(':')
    secret = parts[0][:64]
    kpub = parts[0][64:]
    msg = parts[2]
    sig = parts[3][:128]
    r = sig[:64]
    s = sig[64:]
    return {
        "kpub": kpub,
        "secret": secret,
        "msg": msg,
        "r": r,
        "s": s
    }

def convert_to_json(input_file, output_file):
    data = []
    with open(input_file, 'r') as f:
        for line in f:
            if line.strip():  # Skip empty lines
                data.append(parse_line(line))

    with open(output_file, 'w') as f:
        for entry in data:
            json_line = json.dumps(entry, separators=(',', ':'))
            f.write(json_line + '\n')


if __name__ == "__main__":
    input_file = 'ed25519.input.txt'  # Replace with your input file name
    output_file = 'ed25519tv.json'  # Replace with your desired output file name
    convert_to_json(input_file, output_file)
