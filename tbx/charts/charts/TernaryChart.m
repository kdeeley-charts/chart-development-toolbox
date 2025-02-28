classdef TernaryChart < Component
    %TERNARYCHART Chart managing a barycentric plot of three variables
    %which sum to a constant.

    % Copyright 2018-2025 The MathWorks, Inc.

    properties ( Dependent )
        % Table of data: columns 1-3 are inputs and column 4 is the output.
        Data(:, 4) table {mustBeTernaryData}
        % Resolution of the grid.
        GridResolution(1, 1) double {mustBePositive, mustBeInteger}
        % Tick rate.
        TickRate(1, 1) double {mustBePositive, mustBeInteger}
        % Direction of the ternary plot.
        Direction(1, 1) string {mustBeMember( Direction, ...
            ["clockwise", "counterclockwise"] )}
    end % properties ( Dependent )

    properties ( Dependent )
        % Scatter series marker.
        Marker(1, 1) string {mustBeMarker} = "."
        % Scatter series marker size.
        MarkerSize(1, 1) double {mustBePositive, mustBeFinite} = 36
        % Scatter series marker edge color.
        MarkerEdgeColor = "flat"
        % Scatter series marker face color.
        MarkerFaceColor = "none"
        % Surface face color.
        FaceColor = "flat"
        % Surface edge color.
        EdgeColor = [0, 0, 0]
        % Surface face alpha.
        FaceAlpha(1, 1) double {mustBeInRange( FaceAlpha, 0, 1 )} = 1
        % Surface edge alpha.
        EdgeAlpha(1, 1) double {mustBeInRange( EdgeAlpha, 0, 1 )} = 1
        % Surface line style.
        LineStyle(1, 1) string {mustBeLineStyle} = "-"
        % Surface line width.
        LineWidth(1, 1) double {mustBePositive, mustBeFinite} = 0.5
        % Surface face lighting.
        FaceLighting(1, 1) string {mustBeLighting} = "flat"
        % Surface edge lighting.
        EdgeLighting(1, 1) string {mustBeLighting} = "none"
        % Tick visibility.
        ShowTicks(1, 1) matlab.lang.OnOffSwitchState = "on"
    end % properties ( Dependent )

    properties ( Dependent )
        % Axis line width.
        AxisLineWidth(1, 1) double {mustBePositive, mustBeFinite}
        % Grid visibility.
        GridVisible(1, 1) matlab.lang.OnOffSwitchState
        % Grid line width.
        GridLineWidth(1, 1) double {mustBePositive, mustBeFinite}
        % Scatter series visibility.
        ScatterVisible(1, 1) matlab.lang.OnOffSwitchState
        % Colorbar visibility.
        ColorbarVisible(1, 1) matlab.lang.OnOffSwitchState
        % Visibility of the chart controls.
        Controls(1, 1) matlab.lang.OnOffSwitchState
    end % properties ( Dependent )

    properties ( Dependent, AbortSet )
        % Surface type.
        SurfaceType(1, 1) string {mustBeMember( SurfaceType, ...
            ["surface", "mesh"] )}
        % Surface interpolation method.
        InterpolationMethod(1, 1) string ...
            {mustBeMember( InterpolationMethod, ...
            ["linear", "nearest", "natural", "cubic", "v4"] )}
    end % properties ( Dependent, AbortSet )

    properties ( Access = private )
        % Internal storage for the data property.
        Data_(:, 4) table {mustBeTernaryData} = defaultTernaryData()
        % Internal storage for the grid resolution.
        GridResolution_(1, 1) double {mustBePositive, mustBeInteger} = 10
        % Internal storage for the tick rate.
        TickRate_(1, 1) double {mustBePositive, mustBeInteger} = 1
        % Internal storage for the SurfaceType property.
        SurfaceType_(1, 1) string {mustBeMember( SurfaceType_, ...
            ["surface", "mesh"] )} = "surface"
        % Internal storage for Ternary direction.
        Direction_(1, 1) string {mustBeMember( Direction_, ...
            ["clockwise", "counterclockwise"] )} = "clockwise"
        % Internal storage for the interpolation method.
        InterpolationMethod_(1, 1) string ...
            {mustBeMember( InterpolationMethod_, ...
            ["linear", "nearest", "natural", "cubic", "v4"] )} = "v4"
        % Logical scalar specifying whether a computation is required.
        ComputationRequired(1, 1) logical = false
        % Internal storage to record resolution modification.
        ResolutionModified(1, 1) logical = false
    end % properties ( Access = private )

    properties ( Access = private, Transient, NonCopyable )
        % Chart layout.
        LayoutGrid(:, 1) matlab.ui.container.GridLayout ...
            {mustBeScalarOrEmpty}
        % Chart axes.
        Axes(:, 1) matlab.graphics.axis.Axes {mustBeScalarOrEmpty}
        % Triangular axes boundary.
        LineAxis(:, 1) matlab.graphics.primitive.Line {mustBeScalarOrEmpty}
        % Triangular grid.
        Grid(:, 1) matlab.graphics.primitive.Line {mustBeScalarOrEmpty}
        % Axes ticks.
        Ticks(:, 3) matlab.graphics.primitive.Text
        % Toggle button for the chart controls.
        ToggleButton(:, 1) matlab.ui.controls.ToolbarStateButton ...
            {mustBeScalarOrEmpty}
        % Ternary surface.
        Surface(:, 1) matlab.graphics.primitive.Patch {mustBeScalarOrEmpty}
        % 3D scattered data, plotted using a line object.
        ScatterSeries(:, 1) matlab.graphics.primitive.Line ...
            {mustBeScalarOrEmpty}
        % Internal storage for the x-axis label property.
        XLabel(:, 1) matlab.graphics.primitive.Text {mustBeScalarOrEmpty}
        % Internal storage for the y-axis (left and right) label property.
        YLabel(1, 2) matlab.graphics.primitive.Text
        % Internal storage for the z-axis label property.
        ZLabel(:, 1) matlab.graphics.primitive.Text {mustBeScalarOrEmpty}
        % Pushbutton for rotating the axes clockwise.
        RotateClockwiseButton(:, 1) matlab.ui.control.Button ...
            {mustBeScalarOrEmpty}
        % Pushbutton for rotating the axes conterclockwise.
        RotateCounterclockwiseButton(:, 1) matlab.ui.control.Button ...
            {mustBeScalarOrEmpty}
        % Check box for the axes' colorbar.
        ColorbarCheckBox(:, 1) matlab.ui.control.CheckBox ...
            {mustBeScalarOrEmpty}
        % Check box for the axes' grid visibility.
        GridCheckBox(:, 1) matlab.ui.control.CheckBox {mustBeScalarOrEmpty}
        % Check box for the tick visibility.
        TicksCheckBox(:, 1) matlab.ui.control.CheckBox ...
            {mustBeScalarOrEmpty}        
        % Dropdown menu for selecting the surface type.
        SurfaceTypeDropDown(:, 1) matlab.ui.control.DropDown ...
            {mustBeScalarOrEmpty}
        % Dropdown menu for selecting the interpolation method.
        InterpolationMethodDropDown(:, 1) matlab.ui.control.DropDown ...
            {mustBeScalarOrEmpty}
        % Dropdown menu for selecting the Face Color of the surface.
        FaceAlphaSlider(:, 1) matlab.ui.control.Slider ...
            {mustBeScalarOrEmpty}
        % Slider for selecting the Edge Alpha of the surface.
        LineWidthSlider(:, 1) matlab.ui.control.Slider ...
            {mustBeScalarOrEmpty}
        % Dropdown menu for selecting the scatter plot marker.
        ScatterMarkerDropDown(:, 1) matlab.ui.control.DropDown ...
            {mustBeScalarOrEmpty}
        % Slider for selecting the marker size of the scatter series.
        ScatterSizeDataSlider(:, 1) matlab.ui.control.Slider ...
            {mustBeScalarOrEmpty}
    end % properties ( Access = private, Transient, NonCopyable )

    properties ( Constant, Hidden )
        % Product dependencies.
        Dependencies(1, :) string = "MATLAB"
        % Description.
        ShortDescription(1, 1) string = "Barycentric plot of three" + ...
            " variables summing to a constant"
    end % properties ( Constant, Hidden )

    methods

        function value = get.Data( obj )

            value = obj.Data_;

        end % get.Data

        function set.Data( obj, value )

            % Mark the chart for an update.
            obj.ComputationRequired = true;

            % Set the internal data property.
            obj.Data_ = value;

            % Update the axes.
            obj.Axes.DataAspectRatio = ...
                [1, 1, 2 * (max( value{:, 4} ) - min( value{:, 4} ))];

        end % set.Data

        function value = get.GridResolution( obj )

            value = obj.GridResolution_;

        end % get.GridResolution

        function set.GridResolution( obj, value )

            % Mark the chart for an update.
            obj.ComputationRequired = true;

            % Set the internal data property.
            obj.GridResolution_ = value;
            obj.ResolutionModified = true;

        end % set.GridResolution

        function value = get.TickRate( obj )

            value = obj.TickRate_;

        end % get.TickRate

        function set.TickRate( obj, value )

            % Mark the chart for an update.
            obj.ComputationRequired = true;

            % Set the internal data property.
            obj.TickRate_ = value;

        end % set.TickRate

        function value = get.ShowTicks( obj )

            value = obj.TicksCheckBox.Value;

        end % get.ShowTicks

        function set.ShowTicks( obj, value )

            obj.TicksCheckBox.Value = value;
            obj.onTicksCheckBoxSelected()

        end % set.ShowTicks

        function value = get.SurfaceType( obj )

            value = obj.SurfaceType_;

        end % get.SurfaceType

        function set.SurfaceType( obj, value )

            % Mark the chart for an update.
            obj.ComputationRequired = true;

            % Assign the SurfaceType.
            obj.SurfaceType_ = value;

            % Make sure the dropdown is up-to-date.
            obj.SurfaceTypeDropDown.Value = value;

            switch value
                case "surface"
                    obj.FaceColor = "flat";
                    obj.EdgeColor = [0, 0, 0];
                    obj.FaceAlpha = 1;
                    obj.FaceLighting = "flat";
                    obj.EdgeLighting = "none";
                case "mesh"
                    obj.EdgeColor = ...
                        get( obj.Axes, "defaultSurfaceFaceColor" );
                    obj.FaceAlpha = 0;
                    obj.FaceLighting = "none";
                    obj.EdgeLighting = "flat";
            end % switch/case

        end % set.SurfaceType

        function value = get.InterpolationMethod( obj )

            value = obj.InterpolationMethod_;

        end % get.InterpolationMethod

        function set.InterpolationMethod( obj, value )

            % Mark the chart for an update.
            obj.ComputationRequired = true;

            % Set the interpolation method.
            obj.InterpolationMethod_ = value;

            % Make sure the dropdown is up-to-date.
            obj.InterpolationMethodDropDown.Value = value;

        end % set.InterpolationMethod

        function value = get.Direction( obj )

            value = obj.Direction_;

        end % get.Direction

        function set.Direction( obj, value )

            % Mark the chart for an update.
            obj.ComputationRequired = true;

            % Set the internal data property.
            obj.Direction_ = value;

        end % set.Direction

        function value = get.FaceColor( obj )

            value = obj.Surface.FaceColor;

        end % get.FaceColor

        function set.FaceColor( obj, value )

            % Set the property.
            obj.Surface.FaceColor = value;

        end % set.FaceColor

        function value = get.EdgeColor( obj )

            value = obj.Surface.EdgeColor;

        end % get.EdgeColor

        function set.EdgeColor( obj, value )

            % Validate.
            value = convertCharsToStrings( value );
            if ~isstring( value ) || ~ismember( value, ["flat", "none"] )
                value = validatecolor( value );
            end % if

            % Set the property.
            obj.Surface.EdgeColor = value;

        end % set.EdgeColor

        function value = get.FaceAlpha( obj )

            value = obj.Surface.FaceAlpha;

        end % get.FaceAlpha

        function set.FaceAlpha( obj, value )

            % Set the property.
            obj.Surface.FaceAlpha = value;

            % Make sure the slider is up-to-date
            obj.FaceAlphaSlider.Value = value;
            obj.FaceAlphaSlider.Tooltip = string( value );

        end % set.FaceAlpha

        function value = get.EdgeAlpha( obj )

            value = obj.Surface.EdgeAlpha;

        end % get.EdgeAlpha

        function set.EdgeAlpha( obj, value )

            % Set the property.
            obj.Surface.EdgeAlpha = value;

        end % set.EdgeAlpha

        function value = get.LineStyle( obj )

            value = obj.Surface.LineStyle;

        end % get.LineStyle

        function set.LineStyle( obj, value )

            % Set the property.
            obj.Surface.LineStyle = value;

        end % set.LineStyle

        function value = get.LineWidth( obj )

            value = obj.Surface.LineWidth;

        end % get.LineWidth

        function set.LineWidth( obj, value )

            % Set the property.
            obj.Surface.LineWidth = value;

            % Make sure the slider is up-to-date.
            obj.LineWidthSlider.Value = value;
            obj.LineWidthSlider.Tooltip = string( value );

        end % set.LineWidth

        function value = get.FaceLighting( obj )

            value = obj.Surface.FaceLighting;

        end % get.FaceLighting

        function set.FaceLighting( obj, value )

            % Set the Surface property.
            obj.Surface.FaceLighting = value;

        end % set.FaceLighting

        function value = get.EdgeLighting( obj )

            value = obj.Surface.EdgeLighting;

        end % get.EdgeLighting

        function set.EdgeLighting( obj, value )

            % Set the Surface property.
            obj.Surface.EdgeLighting = value;

        end % set.EdgeLighting

        function value = get.Marker( obj )

            value = obj.ScatterSeries.Marker;

        end % get.Marker

        function set.Marker( obj, value )

            % Set the property.
            obj.ScatterSeries.Marker = value;

            % Make sure the dropdown is up-to-date.
            obj.ScatterMarkerDropDown.Value = value;

        end % set.Marker

        function value = get.MarkerSize( obj )

            value = obj.ScatterSeries.MarkerSize;

        end % get.MarkerSize

        function set.MarkerSize( obj, value )

            % Set the Scatter property.
            obj.ScatterSeries.MarkerSize = value;

            % Make sure the dropdown is up-to-date
            obj.ScatterSizeDataSlider.Value = value;

        end % set.MarkerSize

        function value = get.MarkerEdgeColor( obj )

            value = obj.ScatterSeries.MarkerEdgeColor;

        end % get.MarkerEdgeColor

        function set.MarkerEdgeColor( obj, value )

            % Validate.
            value = convertCharsToStrings( value );
            if ~isstring( value ) || ~ismember( value, ["flat", "none"] )
                value = validatecolor( value );
            end % if

            % Set the property.
            obj.ScatterSeries.MarkerEdgeColor = value;

        end % set.MarkerEdgeColor

        function value = get.MarkerFaceColor( obj )

            value = obj.ScatterSeries.MarkerFaceColor;

        end % get.MarkerFaceColor

        function set.MarkerFaceColor( obj, value )

            % Validate.
            value = convertCharsToStrings( value );
            if ~isstring( value ) || ~ismember( value, ["flat", "none"] )
                value = validatecolor( value );
            end % if

            % Set the property.
            obj.ScatterSeries.MarkerFaceColor = value;

        end % set.MarkerFaceColor

        function value = get.AxisLineWidth( obj )

            value = obj.LineAxis.LineWidth;

        end % get.AxisLineWidth

        function set.AxisLineWidth( obj, value )

            % Set the Axis property.
            obj.LineAxis.LineWidth = value;

        end % set.AxisLineWidth

        function value = get.GridVisible( obj )

            value = obj.Grid.Visible;

        end % get.GridVisible

        function set.GridVisible( obj, value )

            % Set the Grid property.
            obj.Grid.Visible = value;

            % Ensure the grid check box is up-to-date.
            obj.GridCheckBox.Value = value;

        end % set.GridVisible

        function value = get.GridLineWidth( obj )

            value = obj.Grid.LineWidth;

        end % get.GridLineWidth

        function set.GridLineWidth( obj, value )

            % Set the Grid property.
            obj.Grid.LineWidth = value;

        end % set.GridLineWidth

        function value = get.ScatterVisible( obj )

            value = obj.ScatterSeries.Visible;

        end % get.ScatterVisible

        function set.ScatterVisible( obj, value )

            % Set the Scatter property.
            obj.ScatterSeries.Visible = value;

        end % set.ScatterVisible

        function value = get.ColorbarVisible( obj )

            value = obj.Axes.Colorbar;

        end % get.ColorbarVisible

        function set.ColorbarVisible( obj, value )

            if value
                obj.colorbar();
            else
                obj.colorbar( "off" )
            end % if

        end % set.ColorbarVisible

        function value = get.Controls( obj )

            value = obj.ToggleButton.Value;

        end % get.Controls

        function set.Controls( obj, value )

            % Update the toggle button.
            obj.ToggleButton.Value = value;

            % Invoke the toggle button callback.
            obj.onToggleButtonPressed()

        end % set.Controls

    end % methods

    methods

        function obj = TernaryChart( namedArgs )
            %TERNARYCHART Construct a TernaryChart object, given optional
            %name-value arguments.

            arguments ( Input )
                namedArgs.?TernaryChart
            end % arguments ( Input )           

            % Set any user-defined properties.
            set( obj, namedArgs )

        end % constructor

        function xlabel( obj, newlabel, namedArgs )
            %XLABEL Add an x-label to the chart.

            arguments
                obj(1, 1) TernaryChart
                newlabel(1, 1) string
                namedArgs.?matlab.graphics.primitive.Text
            end % arguments

            propertyCell = namedargs2cell( namedArgs );
            set( obj.XLabel, "String", newlabel, propertyCell{:} )

        end % xlabel

        function ylabel( obj, side, newlabel, namedArgs )
            %YLABEL Add left/right y-labels to the chart.

            arguments
                obj(1, 1) TernaryChart
                side (1, 1) string {mustBeMember( side, ...
                    ["right", "left"])}
                newlabel(1, 1) string
                namedArgs.?matlab.graphics.primitive.Text
            end % arguments

            propertyCell = namedargs2cell( namedArgs );

            switch side
                case "left"
                    set( obj.YLabel(1, 1), ...
                        "String", newlabel, propertyCell{:} )
                case "right"
                    set( obj.YLabel(1, 2), ...
                        "String", newlabel,  propertyCell{:} )
            end % switch/case

        end % ylabel

        function zlabel( obj, newlabel, namedArgs )
            %ZLABEL Add a z-label to the chart.

            arguments
                obj(1, 1) TernaryChart
                newlabel(1, 1) string
                namedArgs.?matlab.graphics.primitive.Text
            end % arguments

            propertyCell = namedargs2cell(namedArgs);
            set( obj.ZLabel, "String", newlabel, propertyCell{:} );

        end % zlabel

        function varargout = title( obj, varargin )

            [varargout{1:nargout}] = title( obj.Axes, varargin{:} );

        end % title

        function varargout = colorbar( obj, varargin )

            % Call the colorbar function on the chart's axes.
            [varargout{1:nargout}] = colorbar( obj.Axes, varargin{:} );

            % Ensure the colorbar check box is up-to-date.
            obj.ColorbarCheckBox.Value = ~isempty( obj.Axes.Colorbar );

        end % colorbar

        function varargout = colormap( obj, varargin )

            [varargout{1:nargout}] = colormap( obj.Axes, varargin{:} );

        end % colormap

        function varargout = view( obj, varargin )

            [varargout{1:nargout}] = view( obj.Axes, varargin{:} );

        end % view

        function rotate( obj, dir )
            %ROTATE Rotate the chart in the specified direction.

            arguments
                obj(1, 1) TernaryChart
                dir(1, 1) string ...
                    {mustBeMember( dir, ...
                    ["clockwise", "counterclockwise"] )}
            end % arguments

            labels = [string( obj.XLabel.String );
                string( obj.YLabel(1, 1).String );
                string( obj.YLabel(1, 2).String )];

            switch dir
                
                case "clockwise"
                    
                    obj.Data = obj.Data_(:, [3, 1, 2, 4]);
                    obj.xlabel( labels(3, :) )
                    obj.ylabel( "left", labels(1, :) )
                    obj.ylabel( "right", labels(2, :) )

                case "counterclockwise"
                    
                    obj.Data = obj.Data_(:, [2, 3, 1, 4]);
                    obj.xlabel( labels(2, :) )
                    obj.ylabel( "left", labels(3, :) )
                    obj.ylabel( "right", labels(1, :) )

            end % switch/case

        end % rotate

        function swapdata( obj, pos1, pos2 )
            %SWAPDATA Interchange two chart data variables.

            arguments
                obj(1, 1) TernaryChart
                pos1(1, 1) double {mustBeMember(pos1, 1:3)}
                pos2(1, 1) double {mustBeMember(pos2, 1:3)}
            end % arguments

            % The positions correspond to:
            % 1) x-axis
            % 2) yleft-axis
            % 3) yright-axis
            obj.Data(:, [pos1, pos2]) = obj.Data(:, [pos2, pos1]);
            obj.Data.Properties.VariableNames([pos1, pos2]) = ...
                obj.Data.Properties.VariableNames([pos2, pos1]);
            labels = [obj.XLabel.String;
                obj.YLabel(1, 1).String;
                obj.YLabel(1, 2).String];
            labels([pos1, pos2]) = labels([pos2, pos1]);
            obj.xlabel( labels(1, :) )
            obj.ylabel( "left", labels(2, :) )
            obj.ylabel( "right", labels(3, :) )

        end % swapdata

        function resetLabels( obj )

            % Modify the labels to match the table headers
            obj.XLabel.String = obj.Data_.Properties.VariableNames{1};
            obj.YLabel(1, 1).String = ...
                obj.Data_.Properties.VariableNames{2};
            obj.YLabel(1, 2).String = ...
                obj.Data_.Properties.VariableNames{3};
            obj.ZLabel.String = obj.Data_.Properties.VariableNames{4};

        end % resetLabels

        function exportgraphics( obj, varargin )

            exportgraphics( obj.Axes, varargin{:} )

        end % exportgraphics

    end % methods

    methods ( Access = protected )

        function setup( obj )
            %SETUP Initialize the chart graphics.

            % Define the layout grid.
            obj.LayoutGrid = uigridlayout( obj, [1, 2], ...
                "ColumnWidth", ["1x", "0x"] );

            % Create the chart's axes.
            obj.Axes = axes( "Parent", obj.LayoutGrid, ...
                "DataAspectRatioMode", "manual", ...
                "Visible", "off", ...
                "NextPlot", "add" );
            obj.Axes.Title.Visible = "on";
            obj.ResolutionModified = false;

            % Create the chart's labels.
            obj.XLabel = text( obj.Axes, 0, -0.08, "A", ...
                "HorizontalAlignment", "center" );
            obj.YLabel(1, 1) = text( obj.Axes, ...
                -0.45 * sin( pi/6 ) - 0.08, sqrt( 3 )/4 + 0.08, "B", ...
                "HorizontalAlignment", "center", ...
                "Rotation", 60 );
            obj.YLabel(1, 2) = text( obj.Axes, ...
                0.45 * sin( pi/6 ) + 0.08, sqrt( 3 )/4 + 0.08, "C", ...
                "HorizontalAlignment", "center", ...
                "Rotation", -60 );
            obj.ZLabel = text( obj.Axes, 0, 0.95, "Z", ...
                "HorizontalAlignment", "center" );

            % Create the grid.
            obj.Grid = line( "Parent", obj.Axes, ...
                "XData", NaN, ...
                "YData", NaN, ...
                "Color", "k", ...
                "LineWidth", 1 );

            % Add a state button to show/hide the chart's controls.
            tb = axtoolbar( obj.Axes, "default" );
            iconPath = fullfile( chartsRoot(), "charts", "images", ...
                "Cog.png" );
            obj.ToggleButton = axtoolbarbtn( tb, "state", ...
                "Value", "off", ...
                "Tooltip", "Show chart controls", ...
                "Icon", iconPath, ...
                "ValueChangedFcn", @obj.onToggleButtonPressed );

            % Create the line and surface plot.
            obj.Surface = trisurf( [], NaN, NaN, NaN, ...
                "Parent", obj.Axes );

            % Define the data tips.
            datatip( obj.Surface, "Visible", "off" );
            obj.Surface.DataTipTemplate.DataTipRows(1).Label = ...
                obj.XLabel.String;
            obj.Surface.DataTipTemplate.DataTipRows(2).Label = ...
                obj.YLabel(1, 1).String;
            obj.Surface.DataTipTemplate.DataTipRows(3).Label = ...
                obj.YLabel(1, 2).String;
            obj.Surface.DataTipTemplate.DataTipRows(4).Label = ...
                obj.ZLabel.String;

            % Create the scatter series for the data points.
            obj.ScatterSeries = line( "Parent", obj.Axes, ...
                "XData", NaN, ...
                "YData", NaN, ...
                "ZData", NaN, ...
                "Marker", ".", ...
                "MarkerSize", 5, ...
                "LineStyle", "none" );

            % Define the data tips.
            datatip( obj.ScatterSeries, "Visible", "off" );
            obj.ScatterSeries.DataTipTemplate.DataTipRows(1).Label = ...
                obj.XLabel.String;
            obj.ScatterSeries.DataTipTemplate.DataTipRows(2).Label = ...
                obj.YLabel(1, 1).String;
            obj.ScatterSeries.DataTipTemplate.DataTipRows(3).Label = ...
                obj.YLabel(1, 2).String;
            obj.ScatterSeries.DataTipTemplate.DataTipRows(4).Label = ...
                obj.ZLabel.String;

            % Create outbound triangle.
            obj.LineAxis = line( "Parent", obj.Axes, ...
                "XData", [-0.5, 0.5, 0, -0.5], ...
                "YData", [0, 0, sqrt( 3 )/2, 0], ...
                "ZData", [0, 0, 0, 0], ...
                "Color", "k", ...
                "LineWidth", 2 );

            % Name labels from initial table (or default).
            obj.resetLabels()

            % Configure the chart's axes.
            view( obj.Axes, [0 90] )

            % Add the chart controls.
            p = uipanel( "Parent", obj.LayoutGrid, ...
                "Title", "Chart Controls", ...
                "FontWeight", "bold" );
            vLayout = uigridlayout( p, [3, 1], ...
                "RowHeight", ["fit", "fit"] );

            % Add the chart controls for the axis.
            p = uipanel( "Parent", vLayout, ...
                "Title", "Axis", ...
                "FontWeight", "bold" );
            controlLayout = uigridlayout( p, [3, 2], ...
                "RowHeight", ["fit", "fit", "fit"], ...
                "ColumnWidth", ["1x", "1x"] );

            % Axis rotation controls.
            obj.RotateClockwiseButton = uibutton( ...
                "Parent", controlLayout, ...
                "Text", char( 8635 ), ...
                "FontSize", 30, ...
                "Tooltip", "Rotate clockwise", ...
                "ButtonPushedFcn", @obj.onRotateClockwiseButtonPushed );
            obj.RotateCounterclockwiseButton = uibutton( ...
                "Parent", controlLayout, ...
                "Text", char( 8634 ), ...
                "FontSize", 30, ...
                "Tooltip", "Rotate clockwise", ...
                "ButtonPushedFcn", ...
                @obj.onRotateCounterclockwiseButtonPushed );

            % Axis check boxes.
            obj.ColorbarCheckBox = uicheckbox( ...
                "Parent", controlLayout, ...
                "Value", false, ...
                "Text", "Colorbar", ...
                "Tooltip", "Hide/show colorbar", ...
                "ValueChangedFcn", @obj.onColorbarSelected );
            obj.ColorbarCheckBox.Layout.Column = [1, 2];
            obj.GridCheckBox = uicheckbox( ...
                "Parent", controlLayout, ...
                "Value", true, ...
                "Text", "Grid", ...
                "Tooltip", "Hide/show grid", ...
                "ValueChangedFcn", @obj.onGridSelected );
            obj.GridCheckBox.Layout.Column = [1, 2];
            obj.TicksCheckBox = uicheckbox( ...
                "Parent", controlLayout, ...
                "Value", true, ...
                "Text", "Show ticks", ...
                "Tooltip", "Hide/show ticks", ...
                "ValueChangedFcn", @obj.onTicksCheckBoxSelected );

            % Add controls for the surface.
            p = uipanel( "Parent", vLayout, ...
                "Title", "Surface", ...
                "FontWeight", "bold" );
            controlLayout = uigridlayout( p, [4, 2], ...
                "RowHeight", repmat( "fit", 1, 4 ), ...
                "ColumnWidth", ["1x", "1x"] );

            % Surface type selector.
            uilabel( "Parent", controlLayout, "Text", "Surface type:" );
            obj.SurfaceTypeDropDown = uidropdown( ...
                "Parent", controlLayout, ...
                "Items", ["surface", "mesh"], ...
                "Tooltip", "Select the surface type", ...
                "Value", obj.SurfaceType, ...
                "ValueChangedFcn", @obj.onSufaceTypeSelected );

            % Interpolation method selector.
            uilabel( "Parent", controlLayout, ...
                "Text", "Interpolation method:" );
            obj.InterpolationMethodDropDown = uidropdown( ...
                "Parent", controlLayout, ...
                "Items", ...
                ["linear", "nearest", "natural", "cubic", "v4"], ...
                "Tooltip", "Select the surface type", ...
                "Value", obj.InterpolationMethod, ...
                "ValueChangedFcn", @obj.onInterpolationMethodSelected );

            % Face alpha.
            uilabel( "Parent", controlLayout, "Text", "Face alpha:" );
            obj.FaceAlphaSlider = uislider( ...
                "Parent", controlLayout, ...
                "Value", 1, ...
                "Tooltip", "1", ...
                "Limits", [0, 1], ...
                "MajorTicks", [0, 0.25, 0.5, 0.75, 1], ...
                "MajorTickLabels", ["0", "0.25", "0.5", "0.75", "1"], ...
                "ValueChangedFcn", @obj.onFaceAlphaSelected );

            % Line width.
            uilabel( "Parent", controlLayout, "Text", "Line width:" );
            obj.LineWidthSlider = uislider( ...
                "Parent", controlLayout, ...
                "Value", 1, ...
                "Tooltip", "1", ...
                "Limits", [0.5, 20], ...
                "MajorTicks", [0.5, 5, 10, 15, 20], ...
                "MajorTickLabels", ["0.5", "5", "10", "15", "20"], ...
                "ValueChangedFcn", @obj.onLineWidthSelected );

            % Add controls for the scatter series.
            p = uipanel( "Parent", vLayout, ...
                "Title", "Scatter Series", ...
                "FontWeight", "bold" );
            controlLayout = uigridlayout( p, [2, 2], ...
                "RowHeight", repmat( "fit", 1, 2 ), ...
                "ColumnWidth", ["1x", "1x"] );

            % Scatter series marker type selector.
            uilabel( "Parent", controlLayout, "Text", "Marker:" );
            obj.ScatterMarkerDropDown = uidropdown( ...
                "Parent", controlLayout, ...
                "Items", set( obj.ScatterSeries, "Marker" ), ...
                "Tooltip", "Select the marker for the scatter plot", ...
                "Value", obj.ScatterSeries.Marker, ...
                "ValueChangedFcn", @obj.onScatterMarkerSelected );

            % Scatter series marker size selector.
            uilabel( "Parent", controlLayout, ...
                "Text", "Marker size:" );
            obj.ScatterSizeDataSlider = uislider( ...
                "Parent", controlLayout, ...
                "Value", 5, ...
                "Tooltip", "5", ...
                "Limits", [0.5, 40], ...
                "MajorTicks", [0.5, 10, 20, 30, 40], ...
                "MajorTickLabels", ["0.5", "10", "20", "30", "40"], ...
                "ValueChangedFcn", @obj.onMarkerSizeSelected );

        end % setup

        function update( obj )
            %UPDATE Refresh the chart graphics.

            if obj.ComputationRequired

                % Avoid any conflict when the resolution is changed.
                if obj.ResolutionModified
                    delete( obj.Surface.DataTipTemplate )
                    delete( obj.ScatterSeries.DataTipTemplate )
                    obj.ResolutionModified = false;
                end % if

                % Update the surface.
                tri = tricoords( obj.GridResolution_+1 );
                [xg, yg, zg] = tridata( obj );
                set( obj.Surface, "Vertices", [xg(:), yg(:), zg(:)], ...
                    "Faces", tri(:, :), ...
                    "FaceVertexCData", zg(:), ...
                    "Parent", obj.Axes )

                % Update the scatter series.
                if obj.ScatterVisible
                    [~, x, y, z] = data2cart( obj );
                    set( obj.ScatterSeries, "XData", x(:), ...
                        "YData", y(:), ...
                        "ZData", z(:) )
                else
                    set( obj.ScatterSeries, "XData", NaN, ...
                        "YData", NaN, ...
                        "ZData", NaN )
                end % if

                % Update the ticks.
                delete( obj.Ticks )
                obj.Ticks = createTicks( obj );

                % Update the grid.
                [x, y] = gridcoords( obj );
                set( obj.Grid, "XData", x, ...
                    "YData", y, ...
                    "LineWidth", obj.GridLineWidth, ...
                    "Visible", obj.GridVisible )

                % Update the values in the custom datatips for the surface.
                obj.Surface.DataTipTemplate.DataTipRows(1).Label = ...
                    obj.XLabel.String;
                obj.Surface.DataTipTemplate.DataTipRows(2).Label = ...
                    obj.YLabel(1, 1).String;
                obj.Surface.DataTipTemplate.DataTipRows(3).Label = ...
                    obj.YLabel(1, 2).String;
                obj.Surface.DataTipTemplate.DataTipRows(4).Label = ...
                    obj.ZLabel.String;
                [Ag, Bg, Cg] = cart2tern( obj );

                obj.Surface.DataTipTemplate.DataTipRows(1).Value = Ag;
                obj.Surface.DataTipTemplate.DataTipRows(2).Value = Bg;
                obj.Surface.DataTipTemplate.DataTipRows(3).Value = Cg;
                obj.Surface.DataTipTemplate.DataTipRows(4).Value = ...
                    obj.Surface.ZData;

                % Update the custom datatips for the scatter series.
                obj.ScatterSeries.DataTipTemplate. ...
                    DataTipRows(1).Label = obj.XLabel.String;
                obj.ScatterSeries.DataTipTemplate. ...
                    DataTipRows(2).Label = obj.YLabel(1, 1).String;
                obj.ScatterSeries.DataTipTemplate. ...
                    DataTipRows(3).Label = obj.YLabel(1, 2).String;
                obj.ScatterSeries.DataTipTemplate. ...
                    DataTipRows(4).Label = obj.ZLabel.String;
                [Ag, Bg, Cg] = cart2tern( obj );
                obj.ScatterSeries.DataTipTemplate. ...
                    DataTipRows(1).Value = Ag;
                obj.ScatterSeries.DataTipTemplate. ...
                    DataTipRows(2).Value = Bg;
                obj.ScatterSeries.DataTipTemplate. ...
                    DataTipRows(3).Value = Cg;
                obj.ScatterSeries.DataTipTemplate. ...
                    DataTipRows(4).Value = obj.ScatterSeries.ZData;

                % Mark the chart clean.
                obj.ComputationRequired = false;

            end % if

        end % update

    end % methods ( Access = protected )

    methods ( Access = private )

        function onToggleButtonPressed( obj, ~, ~ )
            %ONTOGGLEBUTTONPRESSED Hide/show the chart controls.

            toggleDown = obj.ToggleButton.Value;

            if toggleDown
                % Show the controls.
                obj.LayoutGrid.ColumnWidth{2} = "fit";
                obj.ToggleButton.Tooltip = "Hide chart controls";
            else
                % Hide the controls.
                obj.LayoutGrid.ColumnWidth{2} = "0x";
                obj.ToggleButton.Tooltip = "Show chart controls";
            end % if

        end % onToggleButtonPressed

        function onRotateClockwiseButtonPushed( obj, ~, ~ )
            %ONROTATECLOCKWISEBUTTONPUSHED Allow the user to rotate the
            %chart in the clockwise direction.

            obj.rotate( "clockwise" )

        end % onRotateClockwiseButtonPushed

        function onRotateCounterclockwiseButtonPushed( obj, ~, ~ )
            %ONROTATECOUNTERCLOCKWISEBUTTONPUSHED Allow the user to
            %rotate the chart in the counterclockwise direction.

            obj.rotate( "counterclockwise" )

        end % onRotateCounterclockwiseButtonPushed

        function onGridSelected( obj, s, ~ )
            %ONGRIDSELECTED Enable/disable the grid.

            checked = s.Value;
            if checked
                obj.GridVisible = "on";
            else
                obj.GridVisible = "off";
            end % if

        end % onGridSelected

        function onColorbarSelected( obj, s, ~ )
            %ONCOLORBARSELECTED Enable/disable the colorbar.

            checked = s.Value;
            if checked
                obj.colorbar;
            else
                obj.colorbar( "off" );
            end % if

        end % onColorbarSelected

        function onTicksCheckBoxSelected( obj, ~, ~ )
            %ONTICKSCHECKBOXSELECTED Show/hide the ticks.

            set( obj.Ticks, "Visible", obj.TicksCheckBox.Value )

        end % onTicksCheckBoxSelected

        function onSufaceTypeSelected( obj, s, ~ )
            %ONSURFACETYPESELECTED Update the surface type.

            obj.SurfaceType = s.Value;

        end % onSurfaceTypeSelected

        function onInterpolationMethodSelected( obj, s, ~ )
            %ONINTERPOLATIONMETHODSELECTED Update the surface type.

            % Mark the chart for an update.
            obj.ComputationRequired = true;

            % Assign the InterpolationMethod.
            obj.InterpolationMethod_ = s.Value;

        end % onInterpolationMethodSelected

        function onFaceAlphaSelected( obj, s, ~ )
            %ONFACEALPHASELECTED Update the face alpha.

            set( obj.Surface, "FaceAlpha", s.Value )
            obj.FaceAlphaSlider.Tooltip = string( s.Value );

        end % onFaceAlphaSelected

        function onLineWidthSelected( obj, s, ~ )
            %ONLINEWIDTHSELECTED Update the line width.

            set( obj.Surface, "LineWidth", s.Value )
            obj.LineWidthSlider.Tooltip = string( s.Value );

        end % onLineWidthSelected

        function onScatterMarkerSelected( obj, s, ~ )
            %ONSCATTERMARKERSELECTED Update the chart when the scatter plot
            %marker style is selected interactively.

            obj.ScatterSeries.Marker = s.Value;

        end % onScatterMarkerSelected

        function onMarkerSizeSelected( obj, s, ~ )
            %ONMARKERSIZESELECTED Update the marker size when the user
            %interacts with the slider.

            obj.ScatterSeries.MarkerSize = s.Value;
            obj.ScatterSizeDataSlider.Tooltip = string( s.Value );

        end % onMarkerSizeSelected

        function [x, y] = tern2cart( obj, A, B, C )
            %TERN2CART Convert the ternary coordinates (A, B, C) to
            %Cartesian coordinates (x, y).

            if obj.Direction_ ~= "clockwise"
                y = C * sind( 60 );
                x = A + y * cotd( 60 ) - 1/2;
            else
                y = B * sind( 60 );
                x = 1 - A - y * cotd( 60 ) - 1/2;
            end % if

        end % tern2cart

        function [A, B, C] = cart2tern( obj )
            %CART2TERN Convert Cartesian coordinates (x, y) to ternary
            %coordinates (A, B, C).

            x = obj.Surface.XData;
            y = obj.Surface.YData;

            if obj.Direction_ ~= "clockwise"
                A = x - y .* cotd( 60 ) - 1/2;
                C = y ./ sind( 60 );
                B = 1 - A - C;
            else
                A = 1 - x - y * cotd( 60 ) - 1/2;
                B = y ./ sind( 60 );
                C = 1 - A - B;
            end % if

        end % cart2tern

        function [f, x, y, z] = data2cart( obj )
            %DATA2CART Compute Cartesian coordinates from the chart data.

            % Compute fractional values for each data point.
            f = obj.Data_{:, :} ./ sum( obj.Data_{:, 1:3}, 2 );
            z = obj.Data_{:, 4};

            % Convert the ternary coordinates to Cartesian coordinates.
            [x, y] = tern2cart( obj, f(:, 1), f(:, 2), f(:, 3) );
            [x, sortIdx] = sort( x );
            y = y(sortIdx);
            z = z(sortIdx);

        end % data2cart

        function [xg, yg, zg] = tridata( obj )
            %TRIDATA Calculate the xg, yg and zg values used for trisurf.

            % First, compute the Cartesian coordinates.
            [f, x, y, z] = data2cart( obj );
            % We have x, y, z as vector data. Use meshgrid to create a
            % grid.
            Ar = linspace( min( f(:, 1) ), max( f(:, 1) ), ...
                obj.GridResolution_+1 );
            Br = linspace( min( f(:, 2) ), max( f(:, 2) ), ...
                obj.GridResolution_+1 );
            [Ag, Bg] = meshgrid( Ar, Br );
            Cg = 1 - (Ag + Bg);
            [xg, yg] = tern2cart( obj, Ag, Bg, Cg );

            % Use griddata to get an array compatible with trisurf.
            zg = griddata(x, y, z, xg, yg, obj.InterpolationMethod_);
            zg(Ag + Bg > 1) = NaN;

        end % tridata

        function ticks = createTicks( obj )
            %CREATETICKS Create ticks around the chart's axes.

            tickPos = 1 : obj.TickRate_ : obj.GridResolution_;
            ticks(numel( tickPos ), 3) = matlab.graphics.primitive.Text;
            
            switch obj.Direction_
                
                case "clockwise"
                
                    ticks(:, 1) = text( obj.Axes, ...
                        1/2 - (tickPos-1) ./ obj.GridResolution_, ...
                        -0.03 * ones( 1, numel( tickPos ) ), ...
                        num2str( round( (tickPos-1) ./ ...
                        obj.GridResolution_, 2 ).' ), ...
                        "HorizontalAlignment", "center" );                        
                    ticks(:, 2) = text( obj.Axes, ...
                        -1/2 + 1/2 * (tickPos-1) ./ ...
                        obj.GridResolution_ - 0.03, ...
                        sqrt( 3 ) / 2 * (tickPos-1) ...
                        / obj.GridResolution_, ...
                        num2str( round( (tickPos-1) ./ ...
                        obj.GridResolution_, 2 ).' ), ...
                        "HorizontalAlignment", "center", ...                        
                        "Rotation", 60 );
                    ticks(:, 3) = text( obj.Axes, ...
                        1/2 * (tickPos-1) ./ ...
                        obj.GridResolution_ + 0.03, ...
                        sqrt( 3 ) / 2 * ...
                        (1 - (tickPos-1) ./ obj.GridResolution_ ), ...
                        num2str( round( (tickPos-1) ./ ...
                        obj.GridResolution_, 2 ).' ), ...
                        "HorizontalAlignment", "center", ...                        
                        "Rotation", -60 );
                
                case "counterclockwise"
                    
                    ticks(tickPos, 1) = text( obj.Axes, ...
                        - 1/2 + (tickPos-1) ./ obj.GridResolution_, ...
                        -0.03 * ones( 1, numel( tickPos ) ), ...
                        num2str( round( (tickPos-1) ./ ...
                        obj.GridResolution_, 2 ).' ), ...
                        "HorizontalAlignment", "center" );
                    ticks(tickPos, 2) = text( obj.Axes, ...
                        - 1/2 * (tickPos-1) ./ ...
                        obj.GridResolution_ - 0.03, ...
                        sqrt( 3 ) / 2 * (1 - (tickPos-1) ./ ...
                        obj.GridResolution_ ), ...
                        num2str( round( (tickPos-1) ./ ...
                        obj.GridResolution_, 2 ).' ), ...
                        "HorizontalAlignment", "center", ...
                        "Rotation", 60 );
                    ticks(tickPos, 3) = text( obj.Axes, ...
                        1/2 - 1/2 * (tickPos-1) ./ ...
                        obj.GridResolution_ + 0.03, ...
                        sqrt( 3 ) / 2 * (tickPos-1) ./ ...
                        obj.GridResolution_, ...
                        num2str( round( (tickPos-1) ./ ...
                        obj.GridResolution_, 2 ).' ), ...
                        "HorizontalAlignment", "center", ...
                        "Rotation", -60 );

            end % switch/case

            set( ticks, "Visible", obj.ShowTicks )

        end % createTicks

        function [x, y] = gridcoords( obj )
            %GRIDCOORDS Compute the grid coordinates.

            % Create an equally-spaced vector.
            t = 1 : (obj.GridResolution_-1);
            
            % First, assemble the x-coordinates.
            x1 = [1/2 - t / obj.GridResolution_;
                -1/2 * t / obj.GridResolution_;
                NaN( 2, obj.GridResolution_-1 )];
            x2 = [1/2 - t / obj.GridResolution_;
                1/2 - 1/2 * t / obj.GridResolution_;
                NaN( 2, obj.GridResolution_-1 )];
            x3 = [-1/2 + 1/2 * t / obj.GridResolution_;
                1/2 - 1/2 * t / obj.GridResolution_;
                NaN( 2, obj.GridResolution_-1 )];
            x = [x1; x2; x3];
            x = x(:);
            
            % Next, assemble the y-coordinates.
            y1 = [zeros( 1, obj.GridResolution_-1 );
                sqrt( 3 ) / 2 * (1 - t / obj.GridResolution_);
                NaN( 2, obj.GridResolution_-1 )];
            y2 = [zeros( 1, obj.GridResolution_-1 );
                sqrt( 3 ) / 2 * t / obj.GridResolution_;
                NaN( 2, obj.GridResolution_-1 )];
            y3 = [sqrt( 3 ) / 2 * t / obj.GridResolution_;
                sqrt( 3 ) / 2 * t / obj.GridResolution_;
                NaN( 2, obj.GridResolution_-1 )];
            y = [y1; y2; y3];
            y = y(:);

        end % gridcoords

    end % methods ( Access = private )

end % classdef

function tc = tricoords( N )
%TRICOORDS Triangulate each square.

[X, Y] = meshgrid( 1:N-1 );
bottomLeft = sub2ind( [N, N], X, Y );
bottomLeft = bottomLeft(:);
bottomRight = bottomLeft + 1;
topLeft = bottomLeft + N;
topRight = topLeft + 1;
tc = [topLeft, bottomLeft, bottomRight;
    topLeft, topRight, bottomRight];

end % tricoords

function t = defaultTernaryData()
%DEFAULTTERNARYDATA Create a default table containing ternary data.

t = table( 0, 0, 1, 1 );
t.Properties.VariableNames = ["A", "B", "C", "Z"];

end % defaultTernaryData

function mustBeTernaryData( t )
%MUSTBETERNARYDATA Validate that the input value t is a table containing
%ternary data in the required form.

if ~isempty( t )

    % Validate the required attributes of the table variables.
    Adata = t{:, 1};
    mustBeFiniteNonnegativeDoubleVector( Adata )

    Bdata = t{:, 2};
    mustBeFiniteNonnegativeDoubleVector( Bdata )

    Cdata = t{:, 3};
    mustBeFiniteNonnegativeDoubleVector( Cdata )

    Zdata = t{:, 4};
    mustBeFiniteDoubleVector( Zdata )

end % if

    function mustBeFiniteNonnegativeDoubleVector( v )

        mustBeFiniteDoubleVector( v )
        mustBeNonnegative( v )

    end % mustBeFiniteNonnegativeDoubleVector

    function mustBeFiniteDoubleVector( v )

        mustBeA( v, "double" )
        mustBeVector( v )
        mustBeFinite( v )

    end % mustBeFiniteDoubleVector

end % mustBeTernaryData