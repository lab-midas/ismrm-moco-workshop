 function ob = Gblock(ob, nblock, varargin)
%function ob = Gblock(ob, nblock, varargin)

if isempty(ob.handle_mtimes_block) & ob.nblock > 1
	error(['The Fatrix of type ' ob.caller ' has no mtimes_block()'])
end

ob.nblock = nblock;

if ~isempty(ob.handle_block_setup)
	ob = feval(ob.handle_block_setup, ob);
end
