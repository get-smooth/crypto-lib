# Avoiding Edge Cases for Double Scalar Multiplication

This notes describes how SCL avoid reject some edge cases as weak keys for ECDSA and Schnor multiplication.

## Use of "ecmulmuladd" inside Schnor and ECDSA

Computation of the uP+vQ operation, refered as "ecmulmuladd" in SCL library is the critic and most consuming operation of signature verification. As such it is optimized in SCL_mulmuladd* files of the library. While a generic library would handle any value for the tuple (u,v,P,Q), SCL rejects as invalid some edge cases to reduce computations. It also takes as granted that the input are verified outside of the function.

## The 4MSM windowed case

The 4MSM consist in two phases: 
 * precomputing all $a_0.P +a_1.2^{128}.P+a_2.Q+a_3.2^{128}Q$, where $a_i$ are bits
 * a multi exponentiation (4 bases) using the precomputations

During the precomputations, the edge cases of addition (if input are equal) are ignored, considering that it would immediately reveal one of seven weak public keys. Considering the 16 values $A=\sum a_i$ of the precomputation, one can deduced that
* $P=Q$  if an error is raised for the values $A$ in   (5, 10, 15)
* $P'=Q \rightarrow Q=(2^{128})P$  if an error is raised for the values $A=6$
* $ P'+P=Q \rightarrow Q = (2^{128}+1)^{-1}P$ if an error is raised for the values $A=7$
* $P=Q'\rightarrow Q=(2^{128})^{-1}P$ if an error is raised for the values $A=9$
* $ P=Q+Q' \rightarrow Q = (2^{128}+1)^{-1}P$ if an error is raised for the values $A=13$
* $ P'=Q+Q' \rightarrow Q = (2^{128}+1)^{-1}P'$ if an error is raised for the values $A=14$
* $ Q'=P+P' \rightarrow Q = { (2^{128}+1) \over 2^{128} }P$ if an error is raised for the values $A=11$
or that the following incorrect input has been provided, as they cannot be equal
* $P=P'$ if an error is raised for $A=3$
* $Q=Q'$  if an error is raised for $A=10$



The validity of the input (P,P',Q,Q') may be tested using the SCL_eccutils.sol library. The function 'SetKey' will revert for incorrect input.
While this function can be computed onchain, it is preferable to perform it offchain to avoid these extra cost.

## The 2MSM windowed case

TBD