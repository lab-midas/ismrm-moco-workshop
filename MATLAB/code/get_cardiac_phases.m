function cbins = get_cardiac_phases(nPE,RM,ECG,nPhases,R)

        TR = (RM(end)-RM(1) + RM(2)-RM(1)) / nPE;
        rmv_trs = 300;
        cbins = cardiac_binning(ECG,RM(1),TR,nPE,nPhases,1,R,rmv_trs);
        
end

