# Cap'n Proto Pipeline Architecture

## The Modular Pipeline

```
Source Code → Parser → AST.capnp → TypeChecker → TypedAST.capnp → FomegaEncoder → Fomega.capnp → Evaluator → Result
     ↓           ↓          ↓            ↓              ↓                ↓             ↓            ↓         ↓
  Python      TS+tree    Zero-copy     Haskell      Zero-copy         OCaml      Zero-copy       Rust    JSON
```

## Cap'n Proto Schema Design

### Core AST Schema

```capnp
# ast.capnp
@0xf0e1d2c3b4a59687;

struct SourceLocation {
  line @0 :UInt32;
  column @1 :UInt32;
  file @2 :Text;
}

struct ASTNode {
  location @0 :SourceLocation;

  union {
    # Literals
    literal :group {
      value @1 :Value;
    }

    # Variables
    variable :group {
      name @2 :Text;
    }

    # Functions
    lambda :group {
      params @3 :List(Text);
      body @4 :ASTNode;
    }

    apply :group {
      func @5 :ASTNode;
      args @6 :List(ASTNode);
    }

    # Let bindings
    let :group {
      name @7 :Text;
      value @8 :ASTNode;
      body @9 :ASTNode;
    }

    # Conditionals
    conditional :group {
      condition @10 :ASTNode;
      thenBranch @11 :ASTNode;
      elseBranch @12 :ASTNode;
    }

    # Data structures
    object :group {
      fields @13 :List(Field);
    }

    array :group {
      items @14 :List(ASTNode);
    }

    # Effects (for Free monad)
    effect :group {
      effectType @15 :EffectType;
      continuation @16 :ASTNode;
    }
  }
}

struct Field {
  name @0 :Text;
  value @1 :ASTNode;
}

struct Value {
  union {
    null @0 :Void;
    bool @1 :Bool;
    int @2 :Int64;
    float @3 :Float64;
    text @4 :Text;
  }
}

enum EffectType {
  readFile @0;
  readEnv @1;
  httpGet @2;
  import @3;
}
```

### Type System Schema

```capnp
# types.capnp
@0xa1b2c3d4e5f60718;

using import "ast.capnp".ASTNode;

struct TypedAST {
  ast @0 :ASTNode;
  type @1 :Type;
  constraints @2 :List(Constraint);
}

struct Type {
  union {
    # Base types
    unit @0 :Void;
    bool @1 :Void;
    int @2 :Void;
    float @3 :Void;
    text @4 :Void;

    # Composite types
    array :group {
      elementType @5 :Type;
    }

    object :group {
      fields @6 :List(FieldType);
    }

    # Function types
    function :group {
      paramTypes @7 :List(Type);
      returnType @8 :Type;
    }

    # Polymorphic types
    typeVariable :group {
      name @9 :Text;
    }

    forall :group {
      variables @10 :List(Text);
      body @11 :Type;
    }
  }
}

struct FieldType {
  name @0 :Text;
  type @1 :Type;
  optional @2 :Bool;
}

struct Constraint {
  union {
    typeEqual :group {
      left @0 :Type;
      right @1 :Type;
    }

    hasField :group {
      objectType @2 :Type;
      fieldName @3 :Text;
      fieldType @4 :Type;
    }
  }
}
```

### System F-omega Schema

```capnp
# fomega.capnp
@0xf1e2d3c4b5a69708;

struct FomegaTerm {
  union {
    # Term constructors
    variable :group {
      name @0 :Text;
      level @1 :UInt32;  # De Bruijn level
    }

    abstraction :group {
      parameter @2 :Text;
      paramType @3 :FomegaType;
      body @4 :FomegaTerm;
    }

    application :group {
      function @5 :FomegaTerm;
      argument @6 :FomegaTerm;
    }

    # Type abstractions (System F)
    typeAbstraction :group {
      typeParam @7 :Text;
      kind @8 :Kind;
      body @9 :FomegaTerm;
    }

    typeApplication :group {
      term @10 :FomegaTerm;
      type @11 :FomegaType;
    }
  }
}

struct FomegaType {
  union {
    # Type constructors
    typeVariable :group {
      name @0 :Text;
    }

    arrow :group {
      domain @1 :FomegaType;
      codomain @2 :FomegaType;
    }

    forall :group {
      variable @3 :Text;
      kind @4 :Kind;
      body @5 :FomegaType;
    }

    # Higher-kinded types (omega)
    typeConstructor :group {
      constructor @6 :FomegaType;
      arguments @7 :List(FomegaType);
    }
  }
}

struct Kind {
  union {
    star @0 :Void;  # Kind of types
    arrow :group {
      domain @1 :Kind;
      codomain @2 :Kind;
    }
  }
}
```

## Pipeline Components

### 1. Parser (TypeScript + Tree-sitter)

```typescript
// parser/src/main.ts
import * as capnp from 'capnp-ts';
import * as ast from './generated/ast.capnp';
import Parser from 'tree-sitter';

export function parseToCapnp(source: string, language: string): Uint8Array {
  const parser = new Parser();
  parser.setLanguage(getLanguage(language));

  const tree = parser.parse(source);
  const message = new capnp.Message();
  const astNode = message.initRoot(ast.ASTNode);

  convertTreeSitterToCapnp(tree.rootNode, astNode);

  return message.toArrayBuffer();
}
```

### 2. Type Checker (Haskell)

```haskell
-- typechecker/src/Main.hs
{-# LANGUAGE OverloadedStrings #-}

import Data.Capnp
import qualified AST.Capnp as AST
import qualified Types.Capnp as Types

main :: IO ()
main = do
  input <- LBS.getContents
  case decode input of
    Left err -> error (show err)
    Right astMsg -> do
      astNode <- AST.get_ASTNode_root astMsg
      typedAst <- typecheck astNode
      LBS.putStr (encode typedAst)

typecheck :: AST.ASTNode -> IO Types.TypedAST
typecheck astNode = do
  -- Hindley-Milner type inference
  inferredType <- inferType astNode
  constraints <- generateConstraints astNode
  return $ Types.TypedAST astNode inferredType constraints
```

### 3. F-omega Encoder (OCaml)

```ocaml
(* fomega-encoder/src/main.ml *)
open Capnp.Std

let encode_to_fomega typed_ast =
  (* Convert TypedAST to System F-omega representation *)
  let rec encode_term = function
    | AST.Lambda (params, body) ->
        List.fold_right (fun param acc ->
          Fomega.Abstraction (param, encode_type param, acc)
        ) params (encode_term body)
    | AST.Apply (func, args) ->
        List.fold_left (fun acc arg ->
          Fomega.Application (acc, encode_term arg)
        ) (encode_term func) args
    (* ... other cases *)
  in
  encode_term typed_ast

let () =
  let input = In_channel.input_all In_channel.stdin in
  let typed_ast = decode_typed_ast input in
  let fomega_term = encode_to_fomega typed_ast in
  let encoded = encode_fomega fomega_term in
  Out_channel.output_string Out_channel.stdout encoded
```

### 4. Evaluator (Rust)

```rust
// evaluator/src/main.rs
use capnp;
use std::io::{self, Read};

mod fomega_capnp {
    include!(concat!(env!("OUT_DIR"), "/fomega_capnp.rs"));
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut buffer = Vec::new();
    io::stdin().read_to_end(&mut buffer)?;

    let message = capnp::serialize::read_message(
        &mut buffer.as_slice(),
        capnp::message::ReaderOptions::new()
    )?;

    let fomega_term = message.get_root::<fomega_capnp::fomega_term::Reader>()?;
    let result = evaluate(fomega_term)?;

    println!("{}", serde_json::to_string(&result)?);
    Ok(())
}

fn evaluate(term: fomega_capnp::fomega_term::Reader) -> Result<serde_json::Value, EvalError> {
    // F-omega self-interpreter goes here
    // This is where the magic happens!
    match term.which()? {
        fomega_capnp::fomega_term::Variable(var) => {
            // Variable lookup
        }
        fomega_capnp::fomega_term::Application(app) => {
            // Function application with strong normalization
        }
        // ... other cases
    }
}
```

## Build System

```toml
# Cargo.toml workspace
[workspace]
members = [
    "parser",
    "typechecker",
    "fomega-encoder",
    "evaluator",
    "cli"
]

[workspace.dependencies]
capnp = "0.18"
serde = "1.0"
serde_json = "1.0"
```

## CLI Integration

```bash
#!/bin/bash
# langlang - The unified config language compiler

SOURCE_FILE="$1"
LANGUAGE="$2"

# Pipeline with Cap'n Proto streams
cat "$SOURCE_FILE" \
  | ./target/release/parser --language="$LANGUAGE" \
  | ./target/release/typechecker \
  | ./target/release/fomega-encoder \
  | ./target/release/evaluator
```

## Performance Benefits

- **Zero-copy**: AST data never gets serialized/deserialized
- **Memory mapping**: Large ASTs stay in GPU-mappable memory
- **Schema validation**: Catches pipeline errors at interface boundaries
- **Parallel processing**: Multiple files can flow through pipeline simultaneously

## Future GPU Integration

```rust
// Future: GPU compilation target
let gpu_kernel = compile_interaction_net(fomega_term)?;
let gpu_result = gpu_kernel.execute_parallel()?;
```

The Cap'n Proto schema already supports the metadata needed for GPU compilation hints and optimization directives.