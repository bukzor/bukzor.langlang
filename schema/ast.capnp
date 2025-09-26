@0xf0e1d2c3b4a59687;

# Core AST representation for the unified configuration language
# All parsers produce this format, all subsequent stages consume it

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

    # Binary operations
    binOp :group {
      operator @15 :BinaryOperator;
      left @16 :ASTNode;
      right @17 :ASTNode;
    }

    # Effects (Free monad representation)
    effect :group {
      effectType @18 :EffectType;
      args @19 :List(ASTNode);
      continuation @20 :ASTNode;
    }

    # Comments (preserved for tooling)
    comment :group {
      content @21 :Text;
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

enum BinaryOperator {
  # Arithmetic
  add @0;
  subtract @1;
  multiply @2;
  divide @3;
  modulo @4;

  # Comparison
  equal @5;
  notEqual @6;
  lessThan @7;
  lessEqual @8;
  greaterThan @9;
  greaterEqual @10;

  # Logical
  logicalAnd @11;
  logicalOr @12;

  # String/Array
  concatenate @13;

  # Object merging (important for config languages)
  merge @14;
}

enum EffectType {
  # File system
  readFile @0;
  writeFile @1;

  # Environment
  readEnv @2;

  # Network
  httpGet @3;
  httpPost @4;

  # Module system
  import @5;

  # Validation/Constraints
  validate @6;

  # Pure computation (for Free monad completeness)
  pure @7;
}