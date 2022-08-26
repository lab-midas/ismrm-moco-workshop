function [cbins] = cardiac_binning(ECG,MRFstart,TR,Nshots,Nphases,sw,R,remove_trans)

% retrospectively bin data into cardiac phases
% ECG: array with timings of ECG R wave detections
% MRFstart: double with the timing of the first readout
% TR: double with sequence TR
% Nshots: int number of sequence readouts
% Nphases: number of target cardiac phases
% sw: double with the fraction of sliding window overlap [0,1]
% R: acceleration, simulates smaller acquisition by removing profiles
% remove_trans: double (in ms) will remove the initial XXX ms of data
% (transient state magnetization)

Ntrans = ceil(remove_trans/TR);

cbins = cell(1,Nphases);
shot_time = MRFstart + [0:Nshots-1]*TR;
tmp_res = 1/(Nphases*sw);

for bbb = 1:Nphases
    % Get data from all heartbeats
    for hhh = 1:numel(ECG)-1
        hb = ECG(hhh+1)-ECG(hhh);
        cp_time = [(((bbb-1)*tmp_res*sw)*hb) + ECG(hhh) ...
                   (((bbb-1)*tmp_res*sw + tmp_res)*hb) + ECG(hhh)];
        currshots = find(shot_time>cp_time(1) & shot_time<cp_time(2));
        cbins{bbb} = cat(2,cbins{bbb},currshots);
    end
    % Get data from last heartbeat
    hhh = numel(ECG);
    hb = mean(ECG(2:end)-ECG(1:end-1));
    cp_time = [(((bbb-1)*tmp_res*sw)*hb) + ECG(hhh) ...
               (((bbb-1)*tmp_res*sw + tmp_res)*hb) + ECG(hhh)];
    currshots = find(shot_time>cp_time(1) & shot_time<cp_time(2));
    cbins{bbb} = cat(2,cbins{bbb},currshots); 
end

cbins_all = cbins;

if R > 1  % undersample (take away end samples first)
    Nshots_acc = Nshots/R;
    for bbb = 1:Nphases
        cbins{bbb}(cbins{bbb}>Nshots_acc) = [];
    end
    
elseif R < -1 % undersample (take away start samples first)
    Nshots_acc = Nshots/R;
    Nshots_acc = Nshots + Nshots_acc;
    cbins2 = cbins;

    min_spokes = 20;
    while(1)
        trial = 1;
        while(1)
            cbins = cbins_all;
            % for very high acc could get empty bins
            range_min = Nshots + (Nshots/R * ((trial-1)+1));
            range_max = range_min - Nshots/R ;
            bflag = 0;
            for bbb = 1:Nphases
                cbins{bbb}(cbins{bbb}<range_min) = [];
                cbins{bbb}(cbins{bbb}>range_max) = [];
                if numel((cbins{bbb}))<min_spokes
                    bflag = 1; % fail state
                end
            end   
            if bflag == 0 % success
                bflag = 2;
                break;
            end
            cbins = cbins2;
            trial = trial + 0.1;
            if range_min < remove_trans
                break; % fail, test next min_spokes
            end
        end
        if bflag == 2
            break;
        end
        min_spokes = min_spokes-1;
    end
end

if remove_trans > 0
    for bbb = 1:Nphases
        cbins{bbb}(cbins{bbb}<Ntrans) = [];    
    end
end

end



