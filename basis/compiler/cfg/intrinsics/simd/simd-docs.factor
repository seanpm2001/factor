USING: compiler.cfg.instructions compiler.cfg.intrinsics.simd
compiler.tree help.markup help.syntax math.vectors ;
IN: compiler.cfg.intrinsics.simd+docs

HELP: emit-simd-v+
{ $values { "node" node } }
{ $description "Emits instructions for SIMD vector addition." }
{ $see-also ##add-vector v+ } ;
