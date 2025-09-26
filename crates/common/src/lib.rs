//! Common types and utilities for the LangLang unified configuration language

pub mod ast_capnp {
    include!(concat!(env!("OUT_DIR"), "/ast_capnp.rs"));
}

pub mod types_capnp {
    include!(concat!(env!("OUT_DIR"), "/types_capnp.rs"));
}

pub mod fomega_capnp {
    include!(concat!(env!("OUT_DIR"), "/fomega_capnp.rs"));
}

use anyhow::Result;
use capnp::serialize;
use std::io::Read;

/// Utilities for working with Cap'n Proto messages in the pipeline
pub struct Pipeline;

impl Pipeline {
    /// Read an AST message from stdin
    pub fn read_ast() -> Result<capnp::message::Reader<capnp::serialize::OwnedSegments>> {
        let stdin = std::io::stdin();
        let mut stdin = stdin.lock();
        let message_reader = serialize::read_message(&mut stdin, capnp::message::ReaderOptions::new())?;
        Ok(message_reader)
    }

    /// Write an AST message to stdout
    pub fn write_ast(message: &capnp::message::Builder<capnp::message::HeapAllocator>) -> Result<()> {
        let stdout = std::io::stdout();
        let mut stdout = stdout.lock();
        serialize::write_message(&mut stdout, message)?;
        Ok(())
    }

    /// Read a TypedAST message from stdin
    pub fn read_typed_ast() -> Result<capnp::message::Reader<capnp::serialize::OwnedSegments>> {
        let stdin = std::io::stdin();
        let mut stdin = stdin.lock();
        let message_reader = serialize::read_message(&mut stdin, capnp::message::ReaderOptions::new())?;
        Ok(message_reader)
    }

    /// Write a TypedAST message to stdout
    pub fn write_typed_ast(message: &capnp::message::Builder<capnp::message::HeapAllocator>) -> Result<()> {
        let stdout = std::io::stdout();
        let mut stdout = stdout.lock();
        serialize::write_message(&mut stdout, message)?;
        Ok(())
    }

    /// Read an F-omega message from stdin
    pub fn read_fomega() -> Result<capnp::message::Reader<capnp::serialize::OwnedSegments>> {
        let stdin = std::io::stdin();
        let mut stdin = stdin.lock();
        let message_reader = serialize::read_message(&mut stdin, capnp::message::ReaderOptions::new())?;
        Ok(message_reader)
    }

    /// Write an F-omega message to stdout
    pub fn write_fomega(message: &capnp::message::Builder<capnp::message::HeapAllocator>) -> Result<()> {
        let stdout = std::io::stdout();
        let mut stdout = stdout.lock();
        serialize::write_message(&mut stdout, message)?;
        Ok(())
    }
}

/// Error types for the pipeline
#[derive(thiserror::Error, Debug)]
pub enum PipelineError {
    #[error("Cap'n Proto serialization error: {0}")]
    Capnp(#[from] capnp::Error),

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Parse error: {message}")]
    Parse { message: String },

    #[error("Type error: {message}")]
    Type { message: String },

    #[error("Encoding error: {message}")]
    Encoding { message: String },

    #[error("Evaluation error: {message}")]
    Evaluation { message: String },
}

/// Common result type for pipeline components
pub type PipelineResult<T> = Result<T, PipelineError>;

/// Metadata about source locations (for error reporting)
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SourceSpan {
    pub file: String,
    pub start_line: u32,
    pub start_column: u32,
    pub end_line: u32,
    pub end_column: u32,
}

impl SourceSpan {
    pub fn new(file: String, start_line: u32, start_column: u32, end_line: u32, end_column: u32) -> Self {
        Self { file, start_line, start_column, end_line, end_column }
    }

    pub fn point(file: String, line: u32, column: u32) -> Self {
        Self::new(file, line, column, line, column)
    }
}

/// Configuration for pipeline stages
#[derive(Debug, Clone)]
pub struct PipelineConfig {
    pub source_language: String,
    pub type_system: TypeSystem,
    pub purity_level: PurityLevel,
    pub optimization_level: OptimizationLevel,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum TypeSystem {
    Dynamic,
    Inferred,     // Hindley-Milner
    Gradual,      // Mix of static/dynamic
    Dependent,    // Dhall-style
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PurityLevel {
    Pure,         // No effects
    Sandbox,      // Limited effects
    Unrestricted, // Any effects
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum OptimizationLevel {
    Debug,        // No optimization, preserve debug info
    Release,      // Standard optimizations
    Aggressive,   // Maximum optimization
}

impl Default for PipelineConfig {
    fn default() -> Self {
        Self {
            source_language: "unknown".to_string(),
            type_system: TypeSystem::Inferred,
            purity_level: PurityLevel::Sandbox,
            optimization_level: OptimizationLevel::Release,
        }
    }
}