# Pystr

Pystr is an extension library of Swift to be available functions of Python str.

## Basic information

To use this library, include Pystr.swift and declare
```
import Pystr
```

## How to use

Call functions in String extention "py", like
```
p = "abcde".py.partition("c") // p is ["ab", "c", "de"]
```

## Notes

Unfortunately Swift's way of handling "¥r¥n" is different from Python's.
If a string includes "¥r¥n", some functions do not work well.

## Authors

toda
