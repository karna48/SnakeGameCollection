function [varargout] = resource(type)
    switch type
        case 'images'
            [varargout{1:nargout}] = load_images();
        case 'sounds'
            [varargout{1:nargout}] = load_sounds();
        otherwise
            error('unknown resource type');
    end
end

function fn = resource_filepath(r_fn)
    fn = fullfile(pwd, '..', 'common_data', r_fn);
end

function [images, sprite_w, sprite_h] = load_images()
    [snake_png, ~, snake_png_alpha] = imread(resource_filepath('Snake.png'));
    names = {'head_up', 'head_right', 'head_down', 'head_left';
             'tail_up', 'tail_right', 'tail_down', 'tail_left';
             'turn_1', 'turn_2', 'turn_3', 'turn_4';
             'vertical', 'horizontal', 'rabbit', 'grass'};
    images = struct();
    [sprite_rows, sprite_cols] = size(names);
    sprite_w = size(snake_png_alpha, 1) / sprite_rows;
    sprite_h = size(snake_png_alpha, 1) / sprite_cols;

    for rc_name = enumerate(names)
        row = rc_name{1}(1);
        col = rc_name{1}(2);
        x1 = floor((row-1)*sprite_w+1);
        x2 = floor(row*sprite_w);
        y1 = floor((col-1)*sprite_h+1);
        y2 = floor(col*sprite_h);
        % fprintf('(%d, %d) -> %d,%d; %d,%d\n', row, col, x1, x2, y1, y2);
        img_rgb = snake_png(x2:-1:x1, y1:y2, :);
        img_alpha = snake_png_alpha(x2:-1:x1, y1:y2, :);
        images.(rc_name{2}) = {img_rgb, img_alpha};
    end
end

function [sounds] = load_sounds()
    for name = {'eat', 'die'}
        [y, Fs] = audioread(resource_filepath([name{1}, '.wav']));
        sounds.(name{1}) = struct('y', y, 'Fs', Fs);
    end
end


