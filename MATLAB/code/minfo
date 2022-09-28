function [mattype,rowd,cold,num,ldpim] = minfo(mat)
% function [mattype,rowd,cold,num] = minfo(mat)
%  or
% function  minfo(mat)
%
%   Return information about a matrix and provides a consistency
%   check for CONSTANT, SYSTEM and VARYING matrices.
%
%   See also: PCK, PSS2SYS, SYS2PSS, UNPCK, and VUNPCK.
%   Copyright 1991-2004 MUSYN Inc. and The MathWorks, Inc.
  largenum = 123456;
  ccla = class(mat);
  csum = sum(ccla);
  ldpim = 0;
  if nargout == 2 | nargout == 3 | nargin ~= 1
    disp('usage: [mattype,rowdata,coldata,num] = minfo(mat)');
    return
  end
  if csum == 635		% double
    if isempty(mat)
      flg = 3;
    else
      [nr,nc] = size(mat);
      if nr == 1 | nc == 1
        flg = -1;
      else
        flg = 0;
        states = mat(1,nc);
        if any(real(mat(2:nr-1,nc))) | any(imag(mat(2:nr-1,nc))) | ...
          any(real(mat(nr,1:nc-1))) | any(imag(mat(nr,1:nc-1)))
          flg = -2;
        elseif states < 0 | mat(nr,nc) ~= -inf
          flg = -2;
        elseif  floor(states) ~= ceil(states)
          flg = -2;
        elseif states >= min([nr,nc])-1
          flg = -2;
        end
        if flg == 0
          flg = 1;
        else
          npts = mat(nr,nc-1);
          if  floor(npts) ~= ceil(npts) | npts <= 0
            flg = -3;
          elseif npts >= nr | mat(nr,nc) ~= inf
            flg = -3;
          elseif  any(real(mat(npts+1:nr-1,nc))) | ...
             any(imag(mat(npts+1:nr-1,nc))) | any(real(mat(nr,1:nc-2))) | ...
             any(imag(mat(nr,1:nc-2)))
            flg = -3;
          end
          if flg == -2
            nrr = round((nr-1)/npts);
            if nrr*npts == nr-1
              flg = 2;
            end
          end
        end
      end
    end
  elseif csum == 414		% char
    [nr,nc] = size(mat);
    flg = 6;
  elseif csum == 230		% ss
    [nr,nc] = size(mat);
    flg = 7;
  else				% unrecognized class
    flg = 8;
  end
  if flg < 0
    if nc==1 & nr>2
        ldpim = mat(1,1);
        if isinf(mat(2))
            nind = mat(3,1);
            if floor(ldpim)==ceil(ldpim) & ldpim>=0  & floor(nind)==ceil(nind) & nind>0
                if nr>3*nind+3
                    pp = mat(4:3*nind+3);
                    if all(floor(pp)==ceil(pp))
                        if all(pp(2*nind+1:3*nind)>=0)
                            if nr==sum(abs(pp(nind+1:2*nind)).*pp(2*nind+1:3*nind))+3*nind+3
                                flg = 4;
                            end
                        end
                    end
                end
            end
        end
    end
 end
 if nargout ~= 4  & nargout ~= 5
   if flg < 0
     disp([int2str(nr) ' rows  ' int2str(nc) ' cols: regular MATLAB matrix'])
   elseif flg == 1
     no = nr-1-states;
     ni = nc-1-states;
     lab1 = ['system:   '];
     lab2 = [int2str(states) ' states     '];
     lab3 = [int2str(no) ' outputs     '];
     lab4 = [int2str(ni) ' inputs     '];
     disp([lab1 lab2 lab3 lab4])
   elseif flg == 2
     cols=nc-1;
     lab1 = ['varying:   '];
     lab2 = [int2str(npts) ' pts     '];
     lab3 = [int2str(nrr) ' rows     '];
     lab4 = [int2str(cols) ' cols     '];
     disp([lab1 lab2 lab3 lab4])
   elseif flg == 3
     disp(['empty matrix']);
   elseif flg == 4
     disp(['packed index matrix:   ' int2str(nind) ' items']);
%   elseif flg == 5
%     disp(['empty packed index matrix']);
   elseif flg == 6
%	MATLAB character string
     disp([int2str(nr) ' rows  ' int2str(nc) ' cols: MATLAB character string'])
   elseif flg == 7
%	MATLAB ss object
     no = nr;
     ni = nc;
     states = size(mat.a,1);
     lab1 = ['MATLAB ss object:   '];
     lab2 = [int2str(states) ' states     '];
     lab3 = [int2str(no) ' outputs     '];
     lab4 = [int2str(ni) ' inputs     '];
     disp([lab1 lab2 lab3 lab4])
   elseif flg == 8
%	other MATLAB object
     disp(['Unknown (' ccla ')']);
   end
 else
   if flg < 0
%    constant matrix
     mattype = 'cons';
     rowd = nr;
     cold = nc;
     num = 0;
   elseif flg == 1
%    system matrix
     mattype = 'syst';
     rowd = nr-1-states;
     cold = nc-1-states;
     num = states;
   elseif flg == 2
%    varying matrix
     mattype = 'vary';
     rowd = nrr;
     cold = nc-1;
     num = npts;
   elseif flg == 3
%    empty matrix
     mattype = 'empt';
     rowd = 0;
     cold = 0;
     num = 0;
   elseif flg == 4
%       pim
    mattype = 'pckd';
    if ldpim == largenum % used to say == 1
        rowd = pp(nind+1:2*nind);
        cold = pp(2*nind+1:3*nind);
        num = pp(1:nind);
        [dum,idx] = sort(num);
        rowd = rowd(idx);
        cold = cold(idx);
        num = dum;
    else
        rowd = pp(nind+1:2*nind);
        cold = pp(2*nind+1:3*nind);
        num = pp(1:nind);
        [dum,idx] = sort(num);
        numc1 = rem(num,ldpim);
        loc = find(numc1==0);
        lloc = length(loc);
        if lloc>0
            numc1(loc) = ldpim*ones(lloc,1);
        end
        num = [numc1 floor((pp(1:nind)-1)/ldpim)+1];
        num = num(idx,:);
        rowd = rowd(idx);
        cold = cold(idx);
    end
   elseif flg == 6
%	MATLAB character string, treated same as constant matrix
     mattype = 'cons';
     rowd = nr;
     cold = nc;
     num = 0;
   elseif flg == 7
%	MATLAB ss object
     mattype = 'ssob';
     rowd = nr;
     cold = nc;
     num = size(mat.a,1);
   elseif flg == 8
%	other MATLAB object
     mattype = 'unkn';
     rowd = size(mat,1);
     cold = size(mat,2);
     num = 0;
   end
 end
%
%
