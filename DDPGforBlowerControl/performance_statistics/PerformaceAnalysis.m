%avg_pid_t_diff = load('avg_pid_t_diff.mat');
%avg_agent_t_diff = load('avg_agent_t_diff.mat');
%total_pid_pwr = load('total_pid_pwr.mat');
%total_agent_pwr = load('total_agent_pwr.mat');

temps = [0 5 10 15 20 25 30 35];

figure(1);
plot(temps, total_pid_pwr(1:8), temps, total_agent_pwr(1:8))
legend('PI Controller', 'DDPG Controller')
xlabel('Environment Temperature (deg C)')
ylabel('Power Usage (W-s)')
title('Total Power Usage')

figure(2);
plot(temps, avg_pid_t_diff(1:8), temps, avg_agent_t_diff(1:8))
legend('PI Controller', 'DDPG Controller')
xlabel('Environment Temperature (deg C)')
ylabel('Average Cabin Temp - Set Temp (deg C)')
title('Temperature Accuracy')

dt = (avg_pid_t_diff(1:8) - avg_agent_t_diff(1:8)) ./ avg_pid_t_diff(1:8);
a_dt = sum(dt) / length(dt);

fprintf('Accuracy advantage %% of DDPG compared to PI: %.2f%%', a_dt*100);

dp = (total_agent_pwr(1:8) - total_pid_pwr(1:8)) ./ total_agent_pwr(1:8);
a_dp = sum(dp) / length(dp);
fprintf('\n\nPower advantage %% of PI compared to DDPG: %.2f%%\n\n', a_dp*100);
