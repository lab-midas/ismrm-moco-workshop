% function out = vnorm(matin,p)
%
%   Norm of a VARYING matrix. VNORM operates just as NORM
%   does in standard MATLAB, but on VARYING matrices also.
%   The option P denotes the norm desired. The default is the
%   infinity norm of MATIN just as with NORM.
%
%   See also: NORM, PKVNORM, VRHO, and VSVD.
%   Copyright 1991-2004 MUSYN Inc. and The MathWorks, Inc.
function out = vnorm(matin,p)
 if nargin == 0
   disp('usage: out = vnorm(matin,p)');
   return
 end
 [mtype,mrows,mcols,mnum] = minfo(matin);
 if nargin == 1
   p = 2;
 end
 if mtype == 'cons'
   out = norm(matin,p);
 elseif mtype == 'vary'
   npts = mnum;
   nrout = mnum;
   ncout = 2;
   out = zeros(npts+1,2);
   ff = (npts+1)*mrows;
   pt = 1:mrows:ff;
   ptm1 = pt(2:npts+1)-1;
   for i=1:npts
     out(i,1) = norm(matin(pt(i):ptm1(i),1:mcols),p);
   end
   out(1:npts,2) = matin(1:npts,mcols+1);
   out(npts+1,1) = npts;
   out(npts+1,2) = inf;
 elseif mtype == 'syst'
   error('VNORM is undefined for SYSTEM matrices');
   return
 else
   out = [];
 end
%
%
