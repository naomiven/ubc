% Naomi Venasquez
% Sophia Ha

% This script sets the controller parameters for the Paint Booth Factory

% ================
% CONTROLLER GAINS
% ================
% Find the values that are stable and allow you to maximize throughtput
% as much as possible without violating the Position Error constraint.

%PID0 = [1 0 0];
%PID1 = [1 0 0];
%PID2 = [1 0 0];

PID0 = [0.0006943 0 0.00095];  %tuned version of [70/95.78 0 1]
PID1 = [187.5 0 1.5];           %tuned version of [125 0 1]
PID2 = [17.5 0 0.14];           %tuned version of [125 0 1]
%PID transfer functions
PID0n = [PID0(3) PID0(1) PID0(2)]; %[Kd Kp Ki]
PIDd = [1 0];   % s term in the denominator

PID1n = [PID1(3) PID1(1) PID1(2)];

PID2n = [PID2(3) PID2(1) PID2(2)];

%pid functions with s on the denominator
%check for stability
DIP0 = tf(PID0n,PIDd);
DIP1 = tf(PID1n, PIDd);
DIP2 = tf(PID2n, PIDd);

% ==========
% THROUGHPUT
% ==========
% Reduce these values as much as possible to increase throughput 
% as much as possible without violating the Position Error constraint.

PaintTime = 3.31;    % Time spent painting truck
ResetTime = 0.5;    % Time spent resetting robot position for next truck


% ===========
% JOINT LIMIT
% ===========
% Modify this value to adjust where the truck is when you begin painting
% it to avoid running into the limit of the Q0 prismatic joint.

StartX    = 0;    % Initial position of truck when painting starts
