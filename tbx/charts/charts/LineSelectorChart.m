classdef LineSelectorChart < Chart
    %LINESELECTORCHART Chart displaying a collection of line plots,
    %possibly on different scales.

    % Copyright 2018-2025 The MathWorks, Inc.

    properties ( Dependent )
        % Chart x-data.
        XData(:, 1) double {mustBeReal}
        % Chart y-data.
        YData(:, :) double {mustBeReal}
    end % properties ( Dependent )

    properties
        % Axes x-grid.
        XGrid(1, 1) matlab.lang.OnOffSwitchState = "on"
        % Axes y-grid.
        YGrid(1, 1) matlab.lang.OnOffSwitchState = "on"
        % Color of the selected line.
        SelectedColor {validatecolor} = [0, 0.447, 0.741]
        % Width of the selected line.
        SelectedLineWidth(1, 1) double {mustBePositive, mustBeFinite} = 3
        % Width of the unselected lines.
        TraceLineWidth(1, 1) double {mustBePositive, mustBeFinite} = 1.5
    end % properties

    properties ( Dependent )
        % Color of the unselected line or lines.
        TraceColor
    end % properties ( Dependent )

    properties ( Access = private )
        % Internal storage for the XData property.
        XData_(:, 1) double {mustBeReal} = double.empty( 0, 1 )
        % Internal storage for the YData property.
        YData_(:, :) double {mustBeReal} = double.empty( 0, 1 )
        % Index of the selected line.
        SelectedLineIndex(1, 1) double ...
            {mustBeNonnegative, mustBeInteger} = 0
        % Internal storage for the TraceColor property.
        TraceColor_(1, 3) double ...
            {mustBeInRange( TraceColor_, 0, 1 )} = [0.5, 0.5, 0.5]
        % Logical scalar specifying whether a computation is required.
        ComputationRequired(1, 1) logical = false
    end % properties ( Access = private )

    properties ( Dependent, Access = private )
        % Chart y-data, rescaled columnwise to lie in the range [0, 1].
        YDataScaled(:, :) double {mustBeReal}
        % Columnwise ranges.
        YDataRange(1, :) double {mustBeReal}
        % Columnwise minima.
        YDataMin(1, :) double {mustBeReal}
    end % properties ( Dependent, Access = private )

    properties ( Access = private, Transient, NonCopyable )
        % Chart axes.
        Axes(:, 1) matlab.graphics.axis.Axes {mustBeScalarOrEmpty}
        % Reset button.
        ResetButton(:, 1) matlab.ui.controls.ToolbarPushButton ...
            {mustBeScalarOrEmpty}
        % Line objects.
        Lines(:, 1) matlab.graphics.primitive.Line
    end % properties ( Access = private, Transient, NonCopyable )

    properties ( Constant, Hidden )
        % Product dependencies.
        Dependencies(1, :) string = "MATLAB"
        % Description.
        ShortDescription(1, 1) string = "Display a collection of " + ...
            "line plots and select one to highlight"
    end % properties ( Constant, Hidden )

    methods

        function value = get.XData( obj )

            value = obj.XData_;

        end % get.XData

        function set.XData( obj, value )

            % Mark the chart for an update.
            obj.ComputationRequired = true;

            % Decide how to modify the chart data.
            nX = numel( value );
            nY = height( obj.YData_ );

            if nX < nY
                % Truncate the y-data if the new x-data is shorter.
                obj.YData_(nX+1:end, :) = [];
            else
                % Otherwise, pad the y-data with NaNs.
                obj.YData_(end+1:nX, :) = NaN();
            end % if

            % Set the internal x-data.
            obj.XData_ = value;

        end % set.XData

        function value = get.YData( obj )

            value = obj.YData_;

        end % get.YData

        function set.YData( obj, value )

            % Mark the chart for an update.
            obj.ComputationRequired = true;

            % Decide how to modify the chart data.
            nX = numel( obj.XData_ );
            nY = height( value );

            if nY < nX
                % Truncate the x-data if the new y-data is shorter.
                obj.XData_(nY+1:end) = [];
            else
                % Otherwise, pad the x-data with NaNs.
                obj.XData_(end+1:nY) = NaN();
            end % if

            % Set the internal y-data.
            if isvector( value )
                obj.YData_ = value(:);
            else
                obj.YData_ = value;
            end % if

        end % set.YData

        function value = get.YDataScaled( obj )

            value = (obj.YData_ - obj.YDataMin) ./ obj.YDataRange;

        end % get.YDataScaled

        function value = get.YDataRange( obj )

            value = max( obj.YData_, [], 1 ) - obj.YDataMin;

        end % get.YDataRange

        function value = get.YDataMin( obj )

            value = min( obj.YData_, [], 1 );

        end % get.YDataMin

        function value = get.TraceColor( obj )

            value = obj.TraceColor_;

        end % get.TraceColor

        function set.TraceColor( obj, value )

            % Set the property value.
            obj.TraceColor_ = validatecolor( value );

            % Update the unselected line(s) if necessary.
            unselectedLineIdx = setdiff( 1:numel( obj.Lines ), ...
                obj.SelectedLineIndex );
            set( obj.Lines(unselectedLineIdx), "Color", value )

        end % set.TraceColor

    end % methods

    methods

        function obj = LineSelectorChart( namedArgs )
            %LINESELECTORCHART Construct a LineSelectorChart, given
            %optional name-value arguments.

            arguments ( Input )
                namedArgs.?LineSelectorChart
            end % arguments ( Input )

            % Set any user-defined properties.
            set( obj, namedArgs )

        end % constructor

        function varargout = xlabel( obj, varargin )

            [varargout{1:nargout}] = xlabel( obj.Axes, varargin{:} );

        end % xlabel

        function varargout = ylabel( obj, varargin )

            [varargout{1:nargout}] = ylabel( obj.Axes, varargin{:} );

        end % ylabel

        function varargout = title( obj, varargin )

            [varargout{1:nargout}] = title( obj.Axes, varargin{:} );

        end % title

        function grid( obj, varargin )

            % Invoke grid on the axes.
            grid( obj.Axes, varargin{:} )
            % Update the chart's decorative properties.
            obj.XGrid = obj.Axes.XGrid;
            obj.YGrid = obj.Axes.YGrid;

        end % grid

        function varargout = legend( obj, varargin )

            % Invoke legend on the axes.
            [varargout{1:nargout}] = legend( obj.Axes, varargin{:} );

            % Reconnect the ItemHitFcn, if necessary.
            if ~isempty( obj.Axes.Legend )
                obj.Axes.Legend.ItemHitFcn = @obj.onLegendClicked;
            end % if

        end % legend

        function varargout = xlim( obj, varargin )

            [varargout{1:nargout}] = xlim( obj.Axes, varargin{:} );

        end % xlim

        function varargout = ylim( obj, varargin )

            [varargout{1:nargout}] = ylim( obj.Axes, varargin{:} );

        end % ylim

        function varargout = axis( obj, varargin )

            [varargout{1:nargout}] = axis( obj.Axes, varargin{:} );

        end % axis

        function select( obj, lineIndex )
            %SELECT Select a line.

            arguments ( Input )
                obj(1, 1) LineSelectorChart
                lineIndex(1, 1) double {mustBeNonnegative, mustBeInteger}
            end % arguments ( Input )

            if lineIndex == 0

                % Reset the chart if no selection is made.
                obj.deselect()

            else

                % Otherwise, check the proposed value.
                numLines = numel( obj.Lines );
                assert( lineIndex <= numLines, ...
                    "LineSelectorChart:InvalidLineIndex", ...
                    "The line index must be a nonnegative scalar" + ...
                    " integer not exceeding the number of lines, %d.", ...
                    numLines )

                % Set the internal value.
                obj.SelectedLineIndex = lineIndex;

                % Update the line color.
                obj.Lines(obj.SelectedLineIndex).Color = obj.SelectedColor;
                obj.Axes.YColor = obj.SelectedColor;

                % Trigger the line selected callback.
                onLineClicked( obj, obj.Lines(obj.SelectedLineIndex) )

            end % if

        end % select

        function deselect( obj )
            %DESELECT Deselect the selected line if one is selected.

            % Enable interactivity and gray out all lines.
            set( obj.Lines, "ButtonDownFcn", @obj.onLineClicked, ...
                "LineWidth", obj.TraceLineWidth, ...
                "Color", obj.TraceColor )

            % Restore the original y-axis color.
            obj.Axes.YColor = obj.Axes.XColor;

            % Record no selection.
            obj.SelectedLineIndex = 0;

        end % deselect

    end % methods

    methods ( Access = protected )

        function setup( obj )
            %SETUP Initialize the chart graphics.

            % Create the chart's axes.
            obj.Axes = axes( "Parent", obj.getLayout() );

            % Add a push button to reset the chart.
            tb = axtoolbar( obj.Axes, "default" );
            iconPath = fullfile( chartsRoot(), "charts", ...
                "images", "Reset.png" );
            obj.ResetButton = axtoolbarbtn( tb, "push", ...
                "Icon", iconPath, ...
                "Tooltip", "Reset the chart", ...
                "ButtonPushedFcn", @obj.onResetButtonPushed );

        end % setup

        function update( obj )
            %UPDATE Refresh the chart graphics.

            if obj.ComputationRequired

                % Count the number of lines required.
                nNew = width( obj.YData_ );

                % Count the number of existing lines.
                nOld = numel( obj.Lines );

                if nNew > nOld
                    % Create new lines.
                    nToCreate = nNew - nOld;
                    for k = 1 : nToCreate
                        obj.Lines(nOld+k) = line( ...
                            obj.Axes, NaN, NaN, ...
                            "Color", obj.TraceColor, ...
                            "DisplayName", "" );
                    end % for
                elseif nNew < nOld
                    % Remove the unnecessary lines.
                    delete( obj.Lines(nNew+1:nOld) );
                    obj.Lines(nNew+1:nOld) = [];
                end % if

                % Update the data for all lines.
                for k = 1:nNew
                    set( obj.Lines(k), "XData", obj.XData_, ...
                        "YData", obj.YDataScaled(:, k) )
                end % for

                % Enable interactivity and gray out all lines.
                deselect( obj )

                % Mark the chart clean.
                obj.ComputationRequired = false;

            end % if

            % Refresh the chart's decorative properties.
            set( obj.Axes, "XGrid", obj.XGrid, ...
                "YGrid", obj.YGrid )
            set( obj.Lines, "LineWidth", obj.TraceLineWidth )
            if obj.SelectedLineIndex > 0
                obj.Lines(obj.SelectedLineIndex).LineWidth = ...
                    obj.SelectedLineWidth;
            end % if

        end % update

    end % methods ( Access = protected )

    methods ( Access = private )

        function onResetButtonPushed( obj, ~, ~ )
            %ONRESETBUTTONPUSHED Reset the chart when the user pushes the
            %reset button on the axes' toolbar.

            deselect( obj )

        end % onResetButtonPushed

        function onLineClicked( obj, s, ~ )

            % Determine the index of the selected line.
            selectedIdx = find( obj.Lines == s );

            % Record this value in the object.
            obj.SelectedLineIndex = selectedIdx;

            % Gray out all lines.
            set( obj.Lines, "LineWidth", obj.TraceLineWidth, ...
                "Color", obj.TraceColor )

            % Highlight the selected line.
            set( obj.Lines(selectedIdx), ...
                "LineWidth", obj.TraceLineWidth, ...
                "Color", obj.SelectedColor, ...
                "YData", obj.YData_(:, selectedIdx) )
            set( obj.Axes, "YColor", obj.SelectedColor )

            % Adjust the y-data for all other lines.
            notSelectedIdx = setdiff( 1:numel( obj.Lines ), selectedIdx );
            for k = notSelectedIdx
                adjustedYData = obj.YDataScaled(:, k) * ...
                    obj.YDataRange(selectedIdx) + ...
                    obj.YDataMin(selectedIdx);
                set( obj.Lines(k), "YData", adjustedYData )
            end % for

        end % onLineClicked

        function onLegendClicked( obj, ~, e )

            onLineClicked( obj, e.Peer )

        end % onLegendClicked

    end % methods ( Access = private )

end % classdef