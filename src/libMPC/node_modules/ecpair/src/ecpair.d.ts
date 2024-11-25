/// <reference types="node" />
import { Network } from './networks';
import * as networks from './networks';
export { networks };
interface ECPairOptions {
    compressed?: boolean;
    network?: Network;
    rng?(arg0: number): Buffer;
}
export interface Signer {
    publicKey: Buffer;
    network?: any;
    sign(hash: Buffer, lowR?: boolean): Buffer;
    getPublicKey?(): Buffer;
}
export interface SignerAsync {
    publicKey: Buffer;
    network?: any;
    sign(hash: Buffer, lowR?: boolean): Promise<Buffer>;
    getPublicKey?(): Buffer;
}
export interface ECPairInterface extends Signer {
    compressed: boolean;
    network: Network;
    lowR: boolean;
    privateKey?: Buffer;
    toWIF(): string;
    verify(hash: Buffer, signature: Buffer): boolean;
    verifySchnorr(hash: Buffer, signature: Buffer): boolean;
    signSchnorr(hash: Buffer): Buffer;
}
export interface ECPairAPI {
    isPoint(maybePoint: any): boolean;
    fromPrivateKey(buffer: Buffer, options?: ECPairOptions): ECPairInterface;
    fromPublicKey(buffer: Buffer, options?: ECPairOptions): ECPairInterface;
    fromWIF(wifString: string, network?: Network | Network[]): ECPairInterface;
    makeRandom(options?: ECPairOptions): ECPairInterface;
}
export interface TinySecp256k1Interface {
    isPoint(p: Uint8Array): boolean;
    pointCompress(p: Uint8Array, compressed?: boolean): Uint8Array;
    isPrivate(d: Uint8Array): boolean;
    pointFromScalar(d?: Uint8Array, compressed?: boolean): Uint8Array;
    sign(h: Uint8Array, d: Uint8Array, e?: Uint8Array): Uint8Array;
    signSchnorr?(h: Uint8Array, d: Uint8Array, e?: Uint8Array): Uint8Array;
    verify(h: Uint8Array, Q: Uint8Array, signature: Uint8Array, strict?: boolean): boolean;
    verifySchnorr?(h: Uint8Array, Q: Uint8Array, signature: Uint8Array): boolean;
}
export declare function ECPairFactory(ecc: TinySecp256k1Interface): ECPairAPI;
