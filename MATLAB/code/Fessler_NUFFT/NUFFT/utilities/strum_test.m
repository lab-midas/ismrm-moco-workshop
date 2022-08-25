 function strum_test
%function strum_test
% test strum object
% Copyright 2006-1-19, Jeff Fessler, University of Michigan

dat.a = 'a';
dat.b = 'b';
h0 = @strum_test_fun0;
h1 = @(st, arg) [st.a arg];
h2 = @(st, arg) sum(arg);

% with comment
st = strum(dat, {'fun0', h0, ''; 'fun1', h1, '(arg)'; 'fun2', h2, '(arg)'})
st.a;
st.fun0;
jf_equal(st.fun1('c'), 'ac')
jf_equal(st.fun2(1:2), 3)

% augment base strum with more methods
new.c = 'c';
s2 = strum(new, {'fun4', @strum_test_fun4, 'fun4(s)'}, 'base', st);
jf_equal(s2.fun4('d'), 'cd')
jf_equal(s2.fun2(1:2), 3)

% without comment
st = strum(dat, {'fun0', h0, 'fun1', h1, 'fun2', h2});
jf_equal(st.fun1('c'), 'ac')
jf_equal(st.fun2(1:2), 3)

st = strum(dat, {'fun0', h0, 'fun3', @strum_test_fun3});
jf_equal(st.fun3('c', 'd'), 'ac')
% [a b] = st.fun3('c', 'd'); % "Too many output arguments" says matlab

% cell arguments
dat.a = {10, 20};
st = strum(dat, {});
st.a;
dat.a{1};
st.a{1};
jf_equal(st.a{1}, dat.a{1})
jf_equal(st.a{2}, dat.a{2})
% jf_equal(dat.a, st.a{:}) % FAILS DUE TO MATLAB LIMITATION :-(
tmp = st.a; jf_equal(dat.a, tmp) % this is the workaround
%st.a{1:2}; % fails
%st.a{:} % fails

try
	[a b] = st.fun2(3)
catch
	warn 'darn, matlab cannot handle multiple outputs, as matt said'
end


function strum_test_fun0(ob)
printm 'ok'
% do nothing

function [a, b] = strum_test_fun3(ob, arg1, arg2)
a = [ob.a arg1];
b = [ob.b arg2];

function c = strum_test_fun4(ob, arg)
c = [ob.c arg];
