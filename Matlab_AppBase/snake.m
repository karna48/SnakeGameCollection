% tested with R2022a

% NOTE R2020a had timer's TimerFcn get event.Data.time with sub-second
% accuracy, but R2022a had only whole seconds, therefore tic/toc

classdef snake < matlab.apps.AppBase
    % Properties that correspond to app components
    properties (Access = public)
        UIFigure     matlab.ui.Figure
        UIAxes       matlab.ui.control.UIAxes
        FPS_label    matlab.graphics.primitive.Text
        length_label matlab.graphics.primitive.Text
        images       struct
        sprite_zoom  double
        sprite_w     int32
        sprite_h     int32
        parts        struct % struct array with fields: row, col, dir, img
        bg_sprites   cell   % {image, ...; image, ...; ...}
        sounds       struct % sound(app.sounds.name.y, app.sounds.name.Fs)
        rows         int32
        cols         int32
        snake_dir    string    % "up", "down", "left", "right"
        snake_dir_next string
        rabbit       struct  % row, col, img
        update_timer timer
        last_update_tic uint64  % tic/toc
        move_t_rem   double
        A_set        int32  % set of all squares [row, col; ...]
    end
 
    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)
            % Create UIFigure and hide until all components are created
            window_size = [1200, 800];
            border_width = 5;

            app.UIFigure = uifigure('Visible', 'off');
            
            app.UIFigure.Position = border_width + [0, 0, border_width+window_size];
            app.UIFigure.Name = 'Snake game (matlab)';
            app.UIFigure.Color = [0.75, 0.75, 1];
            app.UIFigure.AutoResizeChildren = 'off';
            
            app.UIFigure.KeyPressFcn = @app.keyPressed;
            
            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            app.UIAxes.Position = [0, 0, 1200, 800];
            %app.UIAxes.ButtonDownFcn = @app.mouseBtnPressed;
            
            app.UIAxes.XColor = 'none';
            app.UIAxes.YColor = 'none';
            app.UIAxes.Toolbar.Visible = 'off';
            
            axis(app.UIAxes, 'equal')
            
            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
            app.UIFigure.Resize = 'off';
        end

        function update_labels(app)
            fps = 1 / app.update_timer.InstantPeriod;
            app.FPS_label.String = sprintf('FPS: %.2f', fps);
            app.length_label.String = sprintf('Length: %i', length(app.parts));
        end
    end

    % App creation and deletion
    methods (Access = public)
        % Construct app
        function app = snake

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)
            
            app.sprite_zoom = 5;
            [app.images, app.sprite_w, app.sprite_h] = resource('images');
            [app.sounds] = resource('sounds');
            
            app.rows = floor(app.UIAxes.Position(4) / (app.sprite_h*app.sprite_zoom));
            app.cols = floor(app.UIAxes.Position(3) / (app.sprite_w*app.sprite_zoom));
            app.A_set = zeros(app.rows*app.cols, 2);
            for row = 1:app.rows
                for col = 1:app.cols
                    i = sub2ind([app.rows, app.cols], row, col);
                    app.A_set(i, :) = [row, col];
                    app.bg_sprites{row, col} = app.make_sprite('grass', row, col);
                end
            end
            
            fprintf("velikost hraci plochy: %dx%d, max. delka: %d\n", ...
                app.rows, app.cols, app.rows*app.cols)

            % get focus
            figure(app.UIFigure);
            
            app.update_timer = timer(...
                'ExecutionMode', 'fixedRate', ...
                'Period', 1/60, ...
                'TimerFcn', @app.update ...
            );

            app.last_update_tic = [];
            
            app.rabbit = struct('row', 1, 'col', 1, ...
                'img', app.make_sprite('rabbit', 1, 1));

             app.UIAxes.Position(4);

            aylim = ylim(app.UIAxes);

            app.FPS_label = text(app.UIAxes, 2, aylim(2) - 4, 2, "FPS: ???");
            app.length_label = text(app.UIAxes, 2, aylim(2) - 12, 2, "Length: ???");
            for label = [app.FPS_label, app.length_label]
                label.FontName = 'Arial';
                label.FontWeight = 'bold';
                label.FontSize = 30;
                label.Color = [1, 1, 1];
            end

            app.new_game();

            app.update_timer.start();

            if nargout == 0
                clear app
            end
        end

%         function mouseBtnPressed(app, ~, event)
%             figure(app.UIFigure)
%             if event.Button == 1
%                 fprintf("left mouse clicked!\n");
%             end
%         end
        
        function new_game(app)
            app.snake_dir = 'right';
            app.snake_dir_next = 'right';
            
            for part = app.parts
                delete(part.img);
            end
            
            app.parts = struct('row', [], 'col', [], 'dir', "", 'img', []);
            
            app.parts(1) = struct('row', 5, 'col', 6, 'dir', "right", ...
               'img', app.make_sprite('head_right', 5, 6));
            
            app.parts(2) = struct('row', 5, 'col', 5, 'dir', "right", ...
               'img', app.make_sprite('horizontal', 5, 5));

            app.parts(3) = struct('row', 5, 'col', 4, 'dir', "right", ...
               'img', app.make_sprite('tail_right', 5, 4));
            
            app.move_t_rem = 1;
            app.place_rabbit()
            app.update_labels();
        end

        function place_rabbit(app)
            B = zeros(length(app.parts), 2);
            for i = 1:length(app.parts)
                B(i, :) = [app.parts(i).row, app.parts(i).col];
            end
            S = setdiff(app.A_set, B, 'rows');
            if isempty(S)
                disp('victory!!!')
                app.new_game()
            else
                i = randi(size(S, 1));
                app.rabbit.row = S(i, 1);
                app.rabbit.col = S(i, 2);
                app.move_sprite(app.rabbit.img, app.rabbit.row, app.rabbit.col);
            end
        end

        function update(app, ~, ~)
            % [NOTE] cannot use event.Data.time for newer Matlab,
            %        it has only 1s resolution!

            %datestr(event.Data.time)
            if isempty(app.last_update_tic)
                dt = 0;
            else
                % maybe tic/toc would be easier...
                dt = toc(app.last_update_tic);
            end
            app.last_update_tic = tic;
            %fprintf("dt = %f\n", dt);
            
            %MOVE_T = 0.09; % 0.22;
            MOVE_T = 0.05;
            
            app.move_t_rem = app.move_t_rem - dt;
            if app.move_t_rem < 0
                app.move_t_rem = MOVE_T + app.move_t_rem;
                app.snake_dir = app.snake_dir_next;
                snake_head = app.parts(1);
                row = snake_head.row;
                col = snake_head.col;
                switch app.snake_dir
                    case "left"
                        col = col - 1;
                    case "right"
                        col = col + 1;
                    case "up"
                        row = row + 1;
                    case "down"
                        row = row - 1;
                end
                
                % screen wrapping
                row = mod(row-1, app.rows)+1;
                col = mod(col-1, app.cols)+1;

                new_head = struct(...
                    'row', row, 'col', col, ...
                    'dir', app.snake_dir, ...
                    'img', app.make_sprite("head_"+app.snake_dir, row, col));
                
                app.parts = [new_head, app.parts];

                Hd = app.snake_dir;  % new head direction
                Sd = app.parts(2).dir; % second part (old head) direction
                
                if Hd == Sd && (Hd == "left" || Hd == "right")
                    app.change_part_img(2, "horizontal")
                elseif Hd == Sd && (Hd == "down" || Hd == "up")
                    app.change_part_img(2, "vertical")
                elseif Sd == "down"
                    if Hd == "left"
                        app.change_part_img(2, "turn_4")
                    else
                        app.change_part_img(2, "turn_1")
                    end
                elseif Sd == "up"
                    if Hd == "left"
                        app.change_part_img(2, "turn_3")
                    else
                        app.change_part_img(2, "turn_2")
                    end
                elseif Sd == "left"
                    if Hd == "up"
                        app.change_part_img(2, "turn_1")
                    else
                        app.change_part_img(2, "turn_2")
                    end
                elseif Sd == "right"
                    if Hd == "up"
                        app.change_part_img(2, "turn_4")
                    else
                        app.change_part_img(2, "turn_3")
                    end
                end
                
                rabbit_eaten = row == app.rabbit.row && col == app.rabbit.col;
                
                if rabbit_eaten
                    app.place_rabbit()
                    sound(app.sounds.eat.y, app.sounds.eat.Fs)
                else
                    delete(app.parts(end).img)
                    app.parts = app.parts(1:end-1);
                    i = length(app.parts);
                    app.change_part_img(i, "tail_"+app.parts(i-1).dir);
                end
                
                % self-collision -> death, restart
                for i=2:length(app.parts)
                    if row == app.parts(i).row && col == app.parts(i).col
                        sound(app.sounds.die.y, app.sounds.die.Fs)
                        app.new_game()
                        break
                    end
                end
                
                app.update_labels();
            end
        end

        function keyPressed(app, ~, keyData)
            switch keyData.Key
                case {'leftarrow', 'numpad4', 'a'}
                    if app.snake_dir ~= "right"
                        app.snake_dir_next = "left";
                    end
                
                case {'rightarrow', 'numpad6', 'd'}
                    if app.snake_dir ~= "left"
                        app.snake_dir_next = "right";
                    end

                case {'uparrow', 'numpad8', 'w'}
                    if app.snake_dir ~= "down"
                        app.snake_dir_next = "up";
                    end

                case {'downarrow', 'numpad2', 's'}
                    if app.snake_dir ~= "up"
                        app.snake_dir_next = "down";
                    end
                    
                case 'escape'
                    app.delete()
                otherwise
                    %fprintf("key pressed '%s', no action bound\n", keyData.Key)
                    
            end
        end

        function img = make_sprite(app, name, row, col)
            img = image(app.UIAxes, ...
                        'XData', (col-1) * app.sprite_w, ...
                        'YData', (row-1) * app.sprite_h, ...
                        'CData', app.images.(name){1});

            if name ~= "grass"
                img.AlphaData = app.images.(name){2};
            else
                img.AlphaData = 1;  % (no transparency for background)
            end
        end    
         
        function move_sprite(app, img, row, col)
            img.XData = (col-1) * app.sprite_w;
            img.YData = (row-1) * app.sprite_h;
        end
        
        function change_part_img(app, part_idx, name)
            app.parts(part_idx).img.CData = app.images.(name){1};
            if name ~= "grass"
                app.parts(part_idx).img.AlphaData = app.images.(name){2};
            else
                % (no transparency for background)
                app.parts(part_idx).img.AlphaData = 1;  
            end
        end        
        
        % Code that executes before app deletion
        function delete(app)
            % Delete UIFigure when app is deleted
            app.update_timer.stop();
            delete(app.UIFigure)
        end
    end
end
