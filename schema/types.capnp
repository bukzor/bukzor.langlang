@0xa1b2c3d4e5f60718;

using import "ast.capnp".ASTNode;

# Type system representation
# Output of type checker, input to F-omega encoder

struct TypedAST {
  ast @0 :ASTNode;
  type @1 :Type;
  constraints @2 :List(Constraint);
  metadata @3 :TypeMetadata;
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
      length @6 :ArrayLength;
    }

    object :group {
      fields @7 :List(FieldType);
      extensible @8 :Bool;  # Can add more fields?
    }

    # Function types
    function :group {
      paramTypes @9 :List(Type);
      returnType @10 :Type;
      purity @11 :PurityLevel;
    }

    # Polymorphic types (System F)
    typeVariable :group {
      name @12 :Text;
      level @13 :UInt32;  # De Bruijn level
    }

    forall :group {
      variables @14 :List(Text);
      body @15 :Type;
    }

    # Effects (for effect types)
    effect :group {
      effectType @16 :Text;
      resultType @17 :Type;
    }

    # Recursive types
    recursive :group {
      name @18 :Text;
      body @19 :Type;
    }

    # Dependent types (for future Dhall2)
    dependent :group {
      parameter @20 :Text;
      paramType @21 :Type;
      resultType @22 :Type;
    }
  }
}

struct FieldType {
  name @0 :Text;
  type @1 :Type;
  optional @2 :Bool;
  default @3 :ASTNode;  # Default value if any
}

struct ArrayLength {
  union {
    unknown @0 :Void;
    exact @1 :UInt32;
    minimum @2 :UInt32;
    maximum @3 :UInt32;
    range :group {
      min @4 :UInt32;
      max @5 :UInt32;
    }
  }
}

enum PurityLevel {
  pure @0;          # No effects
  controlled @1;    # Limited effects (e.g., read-only)
  unrestricted @2;  # Any effects
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

    subtype :group {
      subtype @5 :Type;
      supertype @6 :Type;
    }

    # Numeric constraints
    range :group {
      type @7 :Type;
      min @8 :Int64;
      max @9 :Int64;
    }

    # String constraints
    pattern :group {
      type @10 :Type;
      regex @11 :Text;
    }

    # Custom constraints (for domain-specific validation)
    custom :group {
      name @12 :Text;
      args @13 :List(ASTNode);
    }
  }
}

struct TypeMetadata {
  # Source information
  sourceType @0 :SourceTypeSystem;

  # Optimization hints
  canInline @1 :Bool;
  isPure @2 :Bool;
  isTotal @3 :Bool;  # Guaranteed to terminate?

  # Documentation
  documentation @4 :Text;

  # For gradual typing
  confidence @5 :TypeConfidence;
}

enum SourceTypeSystem {
  inferred @0;      # Hindley-Milner inference
  annotated @1;     # User-provided types
  gradual @2;       # Mix of inferred/annotated
  dynamic @3;       # No static typing
  dependent @4;     # Dependent types (Dhall-style)
}

enum TypeConfidence {
  certain @0;       # Statically verified
  likely @1;        # High confidence inference
  uncertain @2;     # Best guess
  unknown @3;       # Dynamic typing fallback
}