% create_vcr_matlab.m
% 四旋翼无人机姿态控制 —— VCR 仿真演示视频
% 基于 MATLAB/Simulink，生成 1920x1080 MP4 视频

clear; clc; close all;

%% ================= 配置 =================
SCREENSHOT_DIR = fullfile(fileparts(mfilename('fullpath')), 'screenshots');
VIDEO_PATH = fullfile(getenv('USERPROFILE'), 'Desktop', '四旋翼无人机姿态控制_VCR演示_Simulink.mp4');
VID_W = 1920;
VID_H = 1080;
FPS = 30;

% 配色
GOLD = [0.831, 0.627, 0.118];
BG_DARK = [0.039, 0.059, 0.078];
BG_SLIDE = [0.086, 0.129, 0.169];
WHITE = [0.91, 0.93, 0.94];
WHITE_DIM = [0.63, 0.66, 0.71];
BLUE = [0.25, 0.56, 0.82];
RED = [0.88, 0.31, 0.31];
GREEN = [0.25, 0.75, 0.44];

%% ================= 物理参数 =================
Ixx = 0.012; l_arm = 0.225; Km = 1.0; tau_m = 0.1;
K_plant = Km * l_arm / Ixx;  % 18.75
Kp = 0.923; Ki = 0.417; Kd = 0.187;
K_lqr = [10.00, 4.472, 0.287];

%% ================= 加载或运行仿真数据 =================
mat_file = fullfile(SCREENSHOT_DIR, 'simulation_results.mat');
if exist(mat_file, 'file')
    load(mat_file, 't_pid', 'phi_pid_data', 'u_pid_data', ...
        't_lqr', 'phi_lqr_data', 'u_lqr_data', ...
        't_cas', 'phi_cas_data');
    fprintf('仿真数据已加载\n');
else
    error('请先运行 build_simulink_model.m 生成仿真数据');
end

%% ================= 图形系统预热 =================
% R2026a 图形系统需预热才能用 getframe 捕获可见图窗
% 预热需匹配实际渲染模式（fill+text+背景色），否则大尺寸图窗首次 getframe 仍会失败
warmup = figure('Visible', 'on', 'Position', [1, 1, VID_W/2, VID_H/2], ...
    'Color', BG_DARK, 'Renderer', 'painters');
ax = axes('Position', [0, 0, 1, 1], 'Visible', 'off');
fill([0 1 1 0], [0 0 1 1], BG_DARK, 'EdgeColor', 'none');
text(0.5, 0.5, 'Warmup', 'Color', WHITE, 'HorizontalAlignment', 'center', 'FontSize', 20);
drawnow;
f = getframe(warmup);
close(warmup);
fprintf('图形系统已预热 (getframe: %dx%d)\n', size(f.cdata, 1), size(f.cdata, 2));

%% ================= 视频写入器 =================
v = VideoWriter(VIDEO_PATH, 'MPEG-4');
v.FrameRate = FPS;
v.Quality = 95;
open(v);
fprintf('开始生成视频: %s\n', VIDEO_PATH);

%% ================= 辅助函数 =================
% (使用嵌套函数简化变量共享)

%% ================================================================
%  Scene 1: 标题与模型介绍 (6 秒, 180 帧)
%% ================================================================
fprintf('Scene 1: 标题与模型介绍...\n');

% 预渲染一些静态资源
model_img = imread(fullfile(SCREENSHOT_DIR, '04_pid_simulink_model.png'));
openloop_img = imread(fullfile(SCREENSHOT_DIR, '01_open_loop_analysis.png'));

for frame_i = 1:180
    t_anim = frame_i / FPS;
    fig = figure('Position', [1, 1, VID_W/2, VID_H/2], 'Color', BG_DARK, ...
        'Visible', 'on', 'Renderer', 'painters');
    ax = axes('Position', [0, 0, 1, 1], 'Visible', 'off');
    hold on;

    % 背景
    fill([0 1 1 0], [0 0 1 1], BG_DARK, 'EdgeColor', 'none');

    % 金色装饰线
    fill([0.02 0.98 0.98 0.02], [0.48 0.48 0.485 0.485], GOLD, 'EdgeColor', 'none');

    % 标题 (带淡入效果)
    alpha_title = min(1, t_anim / 1.5);
    text(0.5, 0.75, '四旋翼无人机姿态稳定控制系统设计', ...
        'FontSize', 42, 'FontWeight', 'bold', 'Color', GOLD * alpha_title, ...
        'HorizontalAlignment', 'center', 'FontName', 'Microsoft YaHei');

    % 副标题
    if t_anim > 1.0
        alpha_sub = min(1, (t_anim - 1.0) / 1.0);
        text(0.5, 0.64, '基于 MATLAB/Simulink 的建模、PID/LQR 设计与仿真', ...
            'FontSize', 22, 'Color', WHITE * alpha_sub, ...
            'HorizontalAlignment', 'center', 'FontName', 'Microsoft YaHei');
    end

    % 传递函数 (渐显)
    if t_anim > 2.0
        alpha_tf = min(1, (t_anim - 2.0) / 1.0);
        text(0.5, 0.55, 'G_\phi(s) = 18.75 / [s^2 \cdot (0.1s + 1)]', ...
            'FontSize', 24, 'Color', BLUE * alpha_tf, ...
            'HorizontalAlignment', 'center', 'FontName', 'Consolas');
    end

    % 底部信息
    if t_anim > 3.0
        alpha_info = min(1, (t_anim - 3.0) / 1.0);
        text(0.5, 0.38, '深圳技术大学 · 自动控制原理课程设计', ...
            'FontSize', 18, 'Color', WHITE_DIM * alpha_info, ...
            'HorizontalAlignment', 'center', 'FontName', 'Microsoft YaHei');
        text(0.5, 0.33, '陈培文  202400405059  |  程涛 郭晓东  |  2026.06.14', ...
            'FontSize', 14, 'Color', WHITE_DIM * alpha_info, ...
            'HorizontalAlignment', 'center', 'FontName', 'Microsoft YaHei');
    end

    write_frame(fig, v, VID_W, VID_H);
    close(fig);

    if mod(frame_i, 60) == 0
        fprintf('  Scene 1: %d/180\n', frame_i);
    end
end

%% ================================================================
%  Scene 2: Simulink 模型展示 (8 秒, 240 帧)
%% ================================================================
fprintf('Scene 2: Simulink 模型展示...\n');

for frame_i = 1:240
    t_anim = frame_i / FPS;
    fig = figure('Position', [1, 1, VID_W/2, VID_H/2], 'Color', BG_SLIDE, ...
        'Visible', 'on', 'Renderer', 'painters');

    % 主标题
    ax_main = axes('Position', [0.02, 0.88, 0.96, 0.1], 'Visible', 'off');
    text(0.5, 0.5, 'Simulink 模型搭建 —— PID 与 LQR 闭环控制系统', ...
        'FontSize', 26, 'FontWeight', 'bold', 'Color', GOLD, ...
        'HorizontalAlignment', 'center', 'FontName', 'Microsoft YaHei');

    % 左侧: PID 模型图
    ax_pid = axes('Position', [0.02, 0.08, 0.47, 0.78]);
    imshow(model_img);
    text(10, 25, 'PID 控制器模型', 'FontSize', 14, 'FontWeight', 'bold', ...
        'Color', [1,1,1], 'BackgroundColor', [0,0,0,0.6], 'FontName', 'Microsoft YaHei');

    % 右侧: 模型说明
    ax_desc = axes('Position', [0.52, 0.08, 0.46, 0.78], 'Visible', 'off');

    desc_items = {
        '■ Simulink 模型组成';
        '';
        '  Step: 阶跃输入 0.175 rad (10°)';
        '  PID: Kp=0.923 Ki=0.417 Kd=0.187';
        '  Saturation: ±2.0 抗积分饱和';
        '  Plant: G(s)=18.75/[s²(0.1s+1)]';
        '  Disturbance: 5s 处脉冲 0.05 Nm';
        '';
        '  求解器: ode45 变步长';
        '  最大步长: 0.01 s';
        '  相对容差: 1×10⁻⁶';
        '  仿真时长: 10 s';
    };

    for i = 1:length(desc_items)
        if i <= t_anim * 3  % 逐行动画
            alpha_i = min(1, (t_anim * 3 - i + 1));
            y_pos = 0.95 - i * 0.06;
            if startsWith(desc_items{i}, '■')
                text(0.05, y_pos, desc_items{i}, 'FontSize', 15, ...
                    'FontWeight', 'bold', 'Color', GOLD, ...
                    'FontName', 'Microsoft YaHei', 'VerticalAlignment', 'top');
            else
                text(0.1, y_pos, desc_items{i}, 'FontSize', 13, ...
                    'Color', WHITE, 'FontName', 'Consolas', ...
                    'VerticalAlignment', 'top');
            end
        end
    end

    write_frame(fig, v, VID_W, VID_H);
    close(fig);

    if mod(frame_i, 60) == 0
        fprintf('  Scene 2: %d/240\n', frame_i);
    end
end

%% ================================================================
%  Scene 3: PID 阶跃响应实时动画 (10 秒, 300 帧)
%% ================================================================
fprintf('Scene 3: PID 阶跃响应动画...\n');

step_target = 0.175;

for frame_i = 1:300
    t_anim = frame_i / FPS;
    % 当前显示到仿真时间 t_show
    t_show = min(10, t_anim * 10/10);  % 10s 仿真 → 10s 视频

    fig = figure('Position', [1, 1, VID_W/2, VID_H/2], 'Color', BG_SLIDE, ...
        'Visible', 'on', 'Renderer', 'painters');

    % 标题
    annotation('textbox', [0.02, 0.92, 0.96, 0.06], 'String', ...
        'PID 控制器阶跃响应 —— 根轨迹法整定', ...
        'FontSize', 24, 'FontWeight', 'bold', 'Color', GOLD, ...
        'HorizontalAlignment', 'center', 'EdgeColor', 'none', 'FontName', 'Microsoft YaHei');

    % 响应曲线
    ax1 = subplot(3, 2, [1,2]);

    % 找当前时间对应的数据索引
    idx = find(t_pid <= t_show, 1, 'last');
    if isempty(idx), idx = 1; end

    plot(t_pid(1:idx), phi_pid_data(1:idx), 'b-', 'LineWidth', 2.5);
    hold on;
    yline(step_target, '--', 'LineWidth', 1, 'Color', WHITE_DIM);
    xlabel('时间 (s)', 'FontSize', 12, 'Color', WHITE);
    ylabel('\phi (rad)', 'FontSize', 12, 'Color', WHITE);
    title(sprintf('滚转角响应  t=%.1fs', t_show), 'FontSize', 14, 'FontWeight', 'bold', 'Color', WHITE);
    legend({'PID \phi(t)', '目标 0.175 rad'}, 'TextColor', WHITE, 'Location', 'southeast');
    xlim([0, 10]); ylim([-0.05, 0.32]);
    set(gca, 'Color', BG_DARK, 'XColor', WHITE_DIM, 'YColor', WHITE_DIM);
    grid on;

    % 控制量
    ax2 = subplot(3, 2, [3,4]);
    plot(t_pid(1:idx), u_pid_data(1:idx), 'b-', 'LineWidth', 2);
    xlabel('时间 (s)', 'FontSize', 12, 'Color', WHITE);
    ylabel('控制量 u (V)', 'FontSize', 12, 'Color', WHITE);
    title('控制信号', 'FontSize', 14, 'FontWeight', 'bold', 'Color', WHITE);
    xlim([0, 10]); ylim([-0.5, 3.0]);
    set(gca, 'Color', BG_DARK, 'XColor', WHITE_DIM, 'YColor', WHITE_DIM);
    grid on;

    % PID 参数面板
    ax3 = subplot(3, 2, 5);
    axis off;
    params_text = {
        'PID 参数';
        sprintf('Kp = %.3f', Kp);
        sprintf('Ki = %.3f', Ki);
        sprintf('Kd = %.3f', Kd);
        'N = 100';
        'Anti-windup = ±2.0';
    };
    for i = 1:length(params_text)
        y = 0.95 - i * 0.15;
        if i == 1
            text(0.1, y, params_text{i}, 'FontSize', 14, 'FontWeight', 'bold', ...
                'Color', GOLD, 'FontName', 'Consolas');
        else
            text(0.1, y, params_text{i}, 'FontSize', 13, 'Color', WHITE, ...
                'FontName', 'Consolas');
        end
    end

    % 性能指标（只在动画结束后显示）
    if t_show > 2
        ax4 = subplot(3, 2, 6);
        axis off;
        perf_text = {
            '性能指标';
            sprintf('上升时间 t_r = 0.82 s');
            sprintf('超调 σ = 6.3%%');
            sprintf('调节时间 t_s = 1.85 s');
            sprintf('稳态误差 e_{ss} = 0');
        };
        for i = 1:length(perf_text)
            y = 0.95 - i * 0.18;
            if i == 1
                text(0.1, y, perf_text{i}, 'FontSize', 14, 'FontWeight', 'bold', ...
                    'Color', GOLD, 'FontName', 'Microsoft YaHei');
            else
                text(0.1, y, perf_text{i}, 'FontSize', 13, 'Color', WHITE, ...
                    'FontName', 'Microsoft YaHei');
            end
        end
    end

    write_frame(fig, v, VID_W, VID_H);
    close(fig);

    if mod(frame_i, 60) == 0
        fprintf('  Scene 3: %d/300\n', frame_i);
    end
end

%% ================================================================
%  Scene 4: LQR 阶跃响应动画 (10 秒, 300 帧)
%% ================================================================
fprintf('Scene 4: LQR 阶跃响应动画...\n');

for frame_i = 1:300
    t_anim = frame_i / FPS;
    t_show = min(10, t_anim * 10/10);

    fig = figure('Position', [1, 1, VID_W/2, VID_H/2], 'Color', BG_SLIDE, ...
        'Visible', 'on', 'Renderer', 'painters');

    annotation('textbox', [0.02, 0.92, 0.96, 0.06], 'String', ...
        'LQR 控制器阶跃响应 —— 最优状态反馈', ...
        'FontSize', 24, 'FontWeight', 'bold', 'Color', GOLD, ...
        'HorizontalAlignment', 'center', 'EdgeColor', 'none', 'FontName', 'Microsoft YaHei');

    idx = find(t_lqr <= t_show, 1, 'last');
    if isempty(idx), idx = 1; end

    % 响应曲线
    ax1 = subplot(3, 2, [1,2]);
    plot(t_lqr(1:idx), phi_lqr_data(1:idx), 'r-', 'LineWidth', 2.5);
    hold on;
    yline(step_target, '--', 'LineWidth', 1, 'Color', WHITE_DIM);
    xlabel('时间 (s)', 'FontSize', 12, 'Color', WHITE);
    ylabel('\phi (rad)', 'FontSize', 12, 'Color', WHITE);
    title(sprintf('滚转角响应  t=%.1fs', t_show), 'FontSize', 14, 'FontWeight', 'bold', 'Color', WHITE);
    legend({'LQR \phi(t)', '目标 0.175 rad'}, 'TextColor', WHITE, 'Location', 'southeast');
    xlim([0, 10]); ylim([-0.05, 0.32]);
    set(gca, 'Color', BG_DARK, 'XColor', WHITE_DIM, 'YColor', WHITE_DIM);
    grid on;

    % 控制量
    ax2 = subplot(3, 2, [3,4]);
    plot(t_lqr(1:idx), u_lqr_data(1:idx), 'r-', 'LineWidth', 2);
    xlabel('时间 (s)', 'FontSize', 12, 'Color', WHITE);
    ylabel('控制量 u (V)', 'FontSize', 12, 'Color', WHITE);
    title('控制信号', 'FontSize', 14, 'FontWeight', 'bold', 'Color', WHITE);
    xlim([0, 10]); ylim([-1.0, 3.5]);
    set(gca, 'Color', BG_DARK, 'XColor', WHITE_DIM, 'YColor', WHITE_DIM);
    grid on;

    % LQR 参数
    ax3 = subplot(3, 2, 5);
    axis off;
    lqr_params = {
        'LQR 参数';
        sprintf('K_1 = %.2f  (角度)', K_lqr(1));
        sprintf('K_2 = %.3f  (角速率)', K_lqr(2));
        sprintf('K_3 = %.3f  (电机)', K_lqr(3));
        'Q = diag(100, 1, 1)';
        'R = 1';
    };
    for i = 1:length(lqr_params)
        y = 0.95 - i * 0.15;
        if i == 1
            text(0.1, y, lqr_params{i}, 'FontSize', 14, 'FontWeight', 'bold', ...
                'Color', GOLD, 'FontName', 'Consolas');
        else
            text(0.1, y, lqr_params{i}, 'FontSize', 13, 'Color', WHITE, ...
                'FontName', 'Consolas');
        end
    end

    if t_show > 2
        ax4 = subplot(3, 2, 6);
        axis off;
        lqr_perf = {
            '性能指标';
            '上升时间 t_r = 0.95 s';
            '超调 σ = 2.1%';
            '调节时间 t_s = 1.62 s';
            '稳态误差 e_{ss} = 0';
        };
        for i = 1:length(lqr_perf)
            y = 0.95 - i * 0.18;
            if i == 1
                text(0.1, y, lqr_perf{i}, 'FontSize', 14, 'FontWeight', 'bold', ...
                    'Color', GOLD, 'FontName', 'Microsoft YaHei');
            else
                text(0.1, y, lqr_perf{i}, 'FontSize', 13, 'Color', WHITE, ...
                    'FontName', 'Microsoft YaHei');
            end
        end
    end

    write_frame(fig, v, VID_W, VID_H);
    close(fig);

    if mod(frame_i, 60) == 0
        fprintf('  Scene 4: %d/300\n', frame_i);
    end
end

%% ================================================================
%  Scene 5: PID vs LQR 并排对比 + 抗扰动 (12 秒, 360 帧)
%% ================================================================
fprintf('Scene 5: PID vs LQR 对比动画...\n');

for frame_i = 1:360
    t_anim = frame_i / FPS;
    t_show = min(10, t_anim * 10/12);  % 10s over 12s video

    fig = figure('Position', [1, 1, VID_W/2, VID_H/2], 'Color', BG_SLIDE, ...
        'Visible', 'on', 'Renderer', 'painters');

    annotation('textbox', [0.02, 0.94, 0.96, 0.05], 'String', ...
        'PID vs LQR —— 阶跃响应与抗扰动性能对比', ...
        'FontSize', 22, 'FontWeight', 'bold', 'Color', GOLD, ...
        'HorizontalAlignment', 'center', 'EdgeColor', 'none', 'FontName', 'Microsoft YaHei');

    idx_pid = find(t_pid <= t_show, 1, 'last');
    if isempty(idx_pid), idx_pid = 1; end
    idx_lqr = find(t_lqr <= t_show, 1, 'last');
    if isempty(idx_lqr), idx_lqr = 1; end

    % 左上：角度响应对比
    ax1 = axes('Position', [0.05, 0.55, 0.44, 0.36]);
    plot(t_pid(1:idx_pid), phi_pid_data(1:idx_pid), 'b-', 'LineWidth', 2);
    hold on;
    plot(t_lqr(1:idx_lqr), phi_lqr_data(1:idx_lqr), 'r-', 'LineWidth', 2);
    yline(step_target, '--', 'LineWidth', 1, 'Color', WHITE_DIM);
    xlabel('时间 (s)', 'Color', WHITE);
    ylabel('\phi (rad)', 'Color', WHITE);
    title('滚转角响应', 'FontSize', 14, 'FontWeight', 'bold', 'Color', WHITE);
    legend({'PID', 'LQR'}, 'TextColor', WHITE);
    xlim([0, 10]); ylim([-0.05, 0.32]);
    set(gca, 'Color', BG_DARK, 'XColor', WHITE_DIM, 'YColor', WHITE_DIM);
    grid on;

    % 右上：控制量对比
    ax2 = axes('Position', [0.53, 0.55, 0.44, 0.36]);
    plot(t_pid(1:idx_pid), u_pid_data(1:idx_pid), 'b-', 'LineWidth', 1.5);
    hold on;
    plot(t_lqr(1:idx_lqr), u_lqr_data(1:idx_lqr), 'r-', 'LineWidth', 1.5);
    xlabel('时间 (s)', 'Color', WHITE);
    ylabel('控制量 u (V)', 'Color', WHITE);
    title('控制信号对比', 'FontSize', 14, 'FontWeight', 'bold', 'Color', WHITE);
    legend({'PID', 'LQR'}, 'TextColor', WHITE);
    xlim([0, 10]); ylim([-1.5, 3.5]);
    set(gca, 'Color', BG_DARK, 'XColor', WHITE_DIM, 'YColor', WHITE_DIM);
    grid on;

    % 左下：性能表格
    ax3 = axes('Position', [0.05, 0.05, 0.44, 0.44]);
    axis off;
    table_text = {
        sprintf('指标          PID       LQR');
        sprintf('t_r (s)       0.82      0.95');
        sprintf('σ (%%)         6.3       2.1');
        sprintf('t_s (s)       1.85      1.62');
        sprintf('ISCI (N²s)    0.147     0.089');
        '';
        sprintf('LQR超调低67%%, 能耗低40%%');
    };
    for i = 1:length(table_text)
        text(0.05, 0.95 - i*0.12, table_text{i}, 'FontSize', 13, ...
            'Color', WHITE, 'FontName', 'Consolas', 'VerticalAlignment', 'top');
    end

    % 右下：抗扰动对比
    ax4 = axes('Position', [0.53, 0.05, 0.44, 0.44]);
    % 标注扰动区域
    x_fill = [5, 6, 6, 5];
    y_fill = [-0.05, -0.05, 0.35, 0.35];
    fill(x_fill, y_fill, [1, 0.3, 0.3], 'FaceAlpha', 0.15, 'EdgeColor', 'none');
    hold on;
    plot(t_pid(1:idx_pid), phi_pid_data(1:idx_pid), 'b-', 'LineWidth', 1.8);
    plot(t_lqr(1:idx_lqr), phi_lqr_data(1:idx_lqr), 'r-', 'LineWidth', 1.8);
    xlabel('时间 (s)', 'Color', WHITE);
    ylabel('\phi (rad)', 'Color', WHITE);
    title('抗扰动对比 (t=5s 阵风 0.05 Nm)', 'FontSize', 12, 'FontWeight', 'bold', 'Color', WHITE);
    legend({'扰动区', 'PID', 'LQR'}, 'TextColor', WHITE);
    xlim([0, 10]); ylim([-0.05, 0.32]);
    set(gca, 'Color', BG_DARK, 'XColor', WHITE_DIM, 'YColor', WHITE_DIM);
    grid on;

    write_frame(fig, v, VID_W, VID_H);
    close(fig);

    if mod(frame_i, 60) == 0
        fprintf('  Scene 5: %d/360\n', frame_i);
    end
end

%% ================================================================
%  Scene 6: 总结与感谢 (7 秒, 210 帧)
%% ================================================================
fprintf('Scene 6: 总结与感谢...\n');

for frame_i = 1:210
    t_anim = frame_i / FPS;

    fig = figure('Position', [1, 1, VID_W/2, VID_H/2], 'Color', BG_DARK, ...
        'Visible', 'on', 'Renderer', 'painters');
    ax = axes('Position', [0, 0, 1, 1], 'Visible', 'off');
    hold on;

    fill([0 1 1 0], [0 0 1 1], BG_DARK, 'EdgeColor', 'none');
    fill([0.02 0.98 0.98 0.02], [0.52 0.52 0.525 0.525], GOLD, 'EdgeColor', 'none');

    % 标题
    alpha_title = min(1, t_anim / 1.5);
    text(0.5, 0.82, '总结与展望', 'FontSize', 36, 'FontWeight', 'bold', ...
        'Color', GOLD * alpha_title, 'HorizontalAlignment', 'center', ...
        'FontName', 'Microsoft YaHei');

    % 四点结论 (逐条淡入)
    conclusions = {
        '① 建模: Newton-Euler + 电机一阶惯性 → Gφ(s)=18.75/[s²(0.1s+1)]';
        '② PID: 根轨迹法整定, tr=0.82s, σ=6.3%, ess=0, 工程直观';
        '③ LQR: 最优状态反馈, σ=2.1%, trec=0.91s, 能耗仅PID的60%';
        '④ 双回路串级: 内环PD+外环P, 抗扰性能进一步改善';
    };

    for i = 1:4
        start_time = 1.2 + i * 1.2;
        if t_anim > start_time
            alpha_i = min(1, (t_anim - start_time) / 0.8);
            text(0.08, 0.68 - i * 0.1, conclusions{i}, ...
                'FontSize', 16, 'Color', WHITE * alpha_i, ...
                'FontName', 'Microsoft YaHei');
        end
    end

    % 展望
    if t_anim > 6.0
        alpha_outlook = min(1, (t_anim - 6.0) / 0.8);
        text(0.5, 0.2, '展望: 三轴联合控制 + ESO自抗扰 + PX4 HIL实飞验证', ...
            'FontSize', 18, 'Color', GOLD * alpha_outlook, ...
            'HorizontalAlignment', 'center', 'FontName', 'Microsoft YaHei');
    end


    write_frame(fig, v, VID_W, VID_H);
    close(fig);

    if mod(frame_i, 60) == 0
        fprintf('  Scene 6: %d/210\n', frame_i);
    end
end

%% ================================================================
%  关闭视频
%% ================================================================
close(v);
fprintf('\n视频已保存: %s\n', VIDEO_PATH);

% 获取文件大小
info = dir(VIDEO_PATH);
fprintf('文件大小: %.1f MB\n', info.bytes / 1024 / 1024);
fprintf('总帧数: ~%d\n', 180 + 240 + 300 + 300 + 360 + 210);
fprintf('时长: ~%.0f 秒\n', (180 + 240 + 300 + 300 + 360 + 210) / FPS);
fprintf('分辨率: %d x %d\n', VID_W, VID_H);
fprintf('Done!\n');

%% ================= 辅助函数 =================

function write_frame(fig, video_writer, vid_w, vid_h)
    drawnow;
    pause(0.02);
    frame = getframe(fig);
    img = frame.cdata;
    if size(img, 1) ~= vid_h || size(img, 2) ~= vid_w
        img = imresize(img, [vid_h, vid_w]);
    end
    writeVideo(video_writer, img);
end
