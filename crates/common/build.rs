fn main() {
    capnpc::CompilerCommand::new()
        .src_prefix("../../schema")
        .file("../../schema/ast.capnp")
        .file("../../schema/types.capnp")
        .file("../../schema/fomega.capnp")
        .run()
        .expect("schema compilation");
}