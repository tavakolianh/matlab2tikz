% =========================================================================
% *** FUNCTION matlab2tikz
% ***
% *** Convert figures to TikZ (using pgfplots) for inclusion in LaTeX
% *** documents.
% ***
% *** Workflow:
% ***    0.) Place this file in one of the MATLAB paths
% **         (for example the current directory).
% ***    1.) Create your 2D plot in MATLAB.
% ***    2.) Invoke matlab2tikz by
% ***
% ***        >> matlab2tikz( 'test.tikz' );
% ***
% ***
% *** -------
% ***  Note:
% *** -------
% ***    This program is a rewrite on Paul Wagenaars' Matlab2PGF which
% ***    itself uses pure PGF as output format <paul@wagenaars.org>, see
% ***
% ***       http://www.mathworks.com/matlabcentral/fileexchange/12962
% ***
% ***    In an attempt to simplify and extend things, the idea for
% ***    matlab2tikz has emerged. The goal is to provide the user with a 
% ***    clean interface between the very handy figure creation in MATLAB
% ***    and the powerful means that TikZ with pgfplots has to offer.
% ***
% =========================================================================
% ***
% ***    Copyright (c) 2008, 2009 by
% ***    Nico Schlömer <nico.schloemer@ua.ac.be>
% ***    All rights reserved.
% ***
% ***    This program is free software: you can redistribute it and/or
% ***    modify it under the terms of the GNU General Public License as
% ***    published by the Free Software Foundation, either version 3 of the
% ***    License, or (at your option) any later version.
% ***
% ***    This program is distributed in the hope that it will be useful,
% ***    but WITHOUT ANY WARRANTY; without even the implied warranty of
% ***    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% ***    GNU General Public License for more details.
% ***
% ***    You should have received a copy of the GNU General Public License
% ***    along with this program.  If not, see
% ***    <http://www.gnu.org/licenses/>.
% ***
% =========================================================================
function matlab2tikz( fn )

  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % define some global variables
  clear global matlab2tikz_name;
  clear global matlab2tikz_version;
  clear global tol;
  clear global matlab2tikz_opts;

  global matlab2tikz_name;
  matlab2tikz_name = 'matlab2tikz';

  global matlab2tikz_version;
  matlab2tikz_version = '0.0.2';

  global tol;
  tol = 1e-15; % global round-off tolerance;
               % used, for example, in equality test for doubles

  global matlab2tikz_opts;
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  matlab2tikz_opts.filename = fn;
  matlab2tikz_opts.gca      = gca;
  matlab2tikz_opts.gcf      = gcf;

  fprintf( '%s v%s\n', matlab2tikz_name, matlab2tikz_version );

  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % Save the figure as pgf to file -- here's where the work happens
  save_to_file();
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  fprintf( '\nRemember to load \\usepackage{tikz} and \\usepackage{pgfplots} in the preamble of your LaTeX document.\n\n' );

  % clean up
  clear global matlab2tikz_name;
  clear global matlab2tikz_version;
  clear global tol;
  clear global matlab2tikz_opts;
  clear all;

end
% =========================================================================
% *** END OF FUNCTION matlab2tikz
% =========================================================================



% =========================================================================
% *** FUNCTION save_to_file
% ***
% *** Save the figure as TikZ to a file.
% *** All other routines are called from here.
% ***
% =========================================================================
function save_to_file()

  global filename
  global matlab2tikz_name
  global matlab2tikz_version
  global matlab2tikz_opts

  global neededRGBColors

  fid = fopen( matlab2tikz_opts.filename, 'w' );
  if fid == -1
      error( 'matlab2tikz:save_to_file', ...
             'Unable to open %s for writing', filename );
  end

  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % enter plot recursion --
  % It is important to turn hidden handles on, as visible lines (such as the
  % axes in polar plots, for example), are otherwise hidden from their
  % parental handles (and can hence not be discovered by matlab2tikz).
  % With ShowHiddenHandles 'on', there is no escape. :)
  set( 0, 'ShowHiddenHandles', 'on' );
  fh = gcf;
  str = handle_all_children( fh );
  set( 0, 'ShowHiddenHandles', 'off' );
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % actually print the stuff
  fprintf( fid, '% This file was created by %s v%s.\n\n',               ...
                                   matlab2tikz_name, matlab2tikz_version );

  fprintf( fid, '\\begin{tikzpicture}\n' );

  % don't forget to define the colors
  if size(neededRGBColors,1)
      fprintf( fid, '\n%% defining custom colors\n' );
  end
  for k = 1:size(neededRGBColors,1)
      fprintf( fid, '\\definecolor{mycolor%d}{rgb}{%g,%g,%g}\n', k,     ...
                                                    neededRGBColors(k,:) );
  end

  % print the content
  fprintf( fid, '%s', str );

  fprintf( fid, '\\end{tikzpicture}');
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  fclose( fid );
end
% =========================================================================
% *** END OF FUNCTION save_to_file
% =========================================================================
 


% =========================================================================
% *** FUNCTION handle_all_children
% ***
% *** Draw all children of a graphics object (if they need to be drawn).
% ***
% =========================================================================
function str = handle_all_children( handle )

  str = [];

  children = get( handle, 'Children' );

  % It's important that we go from back to front here, as this is
  % how MATLAB does it, too. Significant for patch (contour) plots,
  % and the order of plotting the colored patches.
  for i = length(children):-1:1
      child = children(i);

      switch get( child, 'Type' )
	  case 'axes'
	      str = [ str, draw_axes( child ) ];

	  case 'line'
	      str = [ str, draw_line( child ) ];

	  case 'patch'
	      str = [ str, draw_patch( child ) ];

	  case 'image'
	      str = [ str, draw_image( child ) ];

	  case 'hggroup'
	      str = [ str, draw_hggroup( child ) ];

	  case { 'hgtransform' }
              % don't handle those directly but descend to its children
              % (which could for example be patch handles)
              str = [ str, handle_all_children( child ) ];

          case { 'uitoolbar', 'uimenu', 'uicontextmenu', 'uitoggletool',...
                 'uitogglesplittool', 'uipushtool', 'hgjavacomponent',  ...
                 'text', 'surface' }
              % don't to anything for these handles and its children

	  otherwise
	      error( 'matfig2tikz:handle_all_children',                 ...
                     'I don''t know how to handle this object: %s\n',   ...
                                                       get(child,'Type') );

      end
  end

end
% =========================================================================
% *** END OF FUNCTION handle_all_children
% =========================================================================



% =========================================================================
% *** FUNCTION draw_axes
% =========================================================================
function str = draw_axes( handle )

  % Make the axis options a global variable as plot objects further below
  % in the hierarchy might want to append something.
  % One example is the required 'ybar stacked' option for stacked bar
  % plots.
  global axis_opts;

  str = [];
  axis_opts = cell(0);

  if ~is_visible( handle )
      % An invisible axis container *can* have visible children, so don't
      % immediately bail out here.
      if length(get(handle,'Children')) > 0
          env  = 'axis';
          dim = get_axes_dimensions( handle );
          axis_opts = [ axis_opts, ...
                        'hide x axis, hide y axis', ...
                        sprintf('width=%g%s, height=%g%s', dim.x, dim.unit,   ...
                                                           dim.y, dim.unit ), ...
                                'scale only axis' ];
          str = plot_axis_environment( handle, env );
      end
      return
  end

  if strcmp( get(handle,'Tag'), 'Colorbar' )
      % handle a colorbar separately
      str = draw_colorbar( handle );
      return
  end

  if strcmp( get(handle,'Tag'), 'legend' )
      % Don't handle the legend here, but further below in the 'axis'
      % environment.
      % In MATLAB, an axes environment and it's corresponding legend are
      % children of the same figure (siblings), while in pgfplots, the
      % \legend (or \addlegendentry) command must appear within the axis
      % environment.
      return
  end

  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % get scales
  xscale = get( handle, 'XScale' );
  yscale = get( handle, 'YScale' );

  is_xlog = strcmp( xscale, 'log' );
  is_ylog = strcmp( yscale, 'log' );

  if  ~is_xlog && ~is_ylog
      env = 'axis';
  elseif is_xlog && ~is_ylog
      env = 'semilogxaxis';
  elseif ~is_xlog && is_ylog
      env = 'semilogyaxis';
  else
      env = 'loglogaxis';
  end
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  axis_opts = [ axis_opts, 'name=main plot' ];

  % the following is general MATLAB behavior
  axis_opts = [ axis_opts, 'axis on top' ];

  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % get the axes dimensions
  dim = get_axes_dimensions( handle );
  axis_opts = [ axis_opts,                                              ...
                sprintf( 'width=%g%s' , dim.x, dim.unit ),              ...
                sprintf( 'height=%g%s', dim.y, dim.unit ),              ...
                'scale only axis' ];
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % get ticks along with the labels
  [ ticks, ticklabels ] = get_ticks( handle );
  if ~isempty( ticks.x )
      axis_opts = [ axis_opts,                              ...
                    sprintf( 'xtick={%s}', ticks.x ) ];
  end
  if ~isempty( ticklabels.x )
      axis_opts = [ axis_opts,                              ...
                    sprintf( 'xticklabels={%s}', ticklabels.x ) ];
  end
  if ~isempty( ticks.y )
      axis_opts = [ axis_opts,                              ...
                    sprintf( 'ytick={%s}', ticks.y ) ];
  end
  if ~isempty( ticklabels.y )
      axis_opts = [ axis_opts,                              ...
                    sprintf( 'yticklabels={%s}', ticklabels.y ) ];
  end
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % get axis labels
  axislabels = get_axislabels( handle );
  if ~isempty( axislabels.x )
      axis_opts = [ axis_opts,                              ...
                          sprintf( 'xlabel={$%s$}',                     ...
                                   escape_characters(axislabels.x) ) ];
  end
  if ~isempty( axislabels.y )
      axis_opts = [ axis_opts,                              ...
                          sprintf( 'ylabel={$%s$}',                     ...
                                   escape_characters(axislabels.y) ) ];
  end
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % get title
  title = get( get( handle, 'Title' ), 'String' );
  if ~isempty(title)
      axis_opts = [ axis_opts,                              ...
                          sprintf( 'title={$%s$}',                      ...
                                   escape_characters(title) ) ];
  end
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % get axis limits
  xlim = get( handle, 'XLim' );
  ylim = get( handle, 'YLim' );
  axis_opts = [ axis_opts,                                  ...
                      sprintf('xmin=%g, xmax=%g', xlim ),               ...
                      sprintf('ymin=%g, ymax=%g', ylim ) ];
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % get grids
  is_grid = 0;
  if strcmp( get( handle, 'XGrid'), 'on' );
      axis_opts = [ axis_opts, 'xmajorgrids' ];
      is_grid = 1;
  end
  if strcmp( get( handle, 'XMinorGrid'), 'on' );
      axis_opts = [ axis_opts, 'xminorgrids' ];
      is_grid = 1;
  end
  if strcmp( get( handle, 'YGrid'), 'on' )
      axis_opts = [ axis_opts, 'ymajorgrids' ];
      is_grid = 1;
  end
  if strcmp( get( handle, 'YMinorGrid'), 'on' );
      axis_opts = [ axis_opts, 'yminorgrids' ];
      is_grid = 1;
  end

  % set the linestyle
  if is_grid
      gridlinestyle = get( handle, 'GridLineStyle' );
      gls           = translate_linestyle( gridlinestyle );
      str = [ str, ...
              sprintf( '\n\\pgfplotsset{every axis grid/.style={style=%s}}\n\n', gls ) ];
  end
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % See if there are any legends that need to be plotted.
  c = get( get(handle,'Parent'), 'Children' ); % siblings of this handle
  legend_handle = 0;
  for k=1:size(c)
      if  strcmp( get(c(k),'Type'), 'axes'   ) && ...
          strcmp( get(c(k),'Tag' ), 'legend' )
          legend_handle = c(k);
          break
      end
  end

  if legend_handle
      axis_opts = [ axis_opts, ...
                    get_legend_opts( legend_handle ) ];
  end
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  % actually begin drawing
  str = [ str, ...
          plot_axis_environment( handle, env ) ];

  % -----------------------------------------------------------------------
  function str = plot_axis_environment( handle, env )

      str = [];

      % First, run through all the children to give them the chance to
      % contribute to 'axis_opts'.
      matfig2pgf_opt.CurrentAxesHandle = handle;
      children_str = handle_all_children( handle );

      % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      % Format 'axis_opts' nicely.
      opts = [ '%%\n', collapse( axis_opts, ',%%\n' ), '%%\n' ];
      % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      % Now, return the whole axis environment.
      str = [ str, ...
              sprintf( ['\n\\begin{%s}[',opts,']\n'], env ), ...
              children_str, ...
              sprintf( '\\end{%s}\n\n', env ) ];
  end
  % -----------------------------------------------------------------------

end
% =========================================================================
% *** END OF FUNCTION draw_axes
% =========================================================================



% =========================================================================
% *** FUNCTION draw_line
% =========================================================================
function str = draw_line( handle )

  str = [];

  if ~is_visible( handle )
      return
  end

  linestyle = get( handle, 'LineStyle' );
  linewidth = get( handle, 'LineWidth' );
  marker    = get( handle, 'Marker' );

  if (    ( strcmp(linestyle,'none') || linewidth==0 )                  ...
       && strcmp(marker,'none') )
      return
  end

  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % deal with draw options
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  color  = get( handle, 'Color' );
  xcolor = get_color( handle, color, 'patch' );
  draw_options = [ sprintf( 'color=%s', xcolor ),            ... % color
                   get_line_options( linestyle, linewidth ), ... % line options
                   get_marker_options( handle )              ... % marker options
                 ];

  % insert draw options
  opts = [ '%%\n', collapse( draw_options, ',%%\n' ), '%%\n' ];
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % plot the actual line data
  % -- Check for any node if it needs to be included at all. For zoomed
  %    plots, lots can be omitted.
  p      = get( handle, 'Parent' );
  xlim   = get( p, 'XLim' );
  ylim   = get( p, 'YLim' );
  xdata  = get( handle, 'XData' );
  ydata  = get( handle, 'YData' );
  segvis = segment_visible( [xdata', ydata'], xlim, ylim );

  n = length(xdata);

  % The line gets actually broken up into several as some parts of it may
  % be outside the visible area (the plot box).
  % 'segvis' tells us which segment are actually visible, and the
  % following construction loops throught it and makes sure that each
  % point that is necessary gets actually printed.
  % 'print_previous' tells whether or not the previous segment is visible;
  % this information is used for determining when a new 'addplot' needs
  % to be opened.
  print_previous = 0;
  for k = 1:n-1
      if segvis(k) % segment is visible
          if ~print_previous % .. the previous wasn't, hence start a plot
              str = [ str, ...
                      sprintf( ['\\addplot [',opts,'] coordinates{\n' ] ), ...;
                      sprintf( ' (%g,%g)', xdata(k), ydata(k) ) ];
              print_previous = 1;
          end
          str = [ str, sprintf( ' (%g,%g)', xdata(k+1), ydata(k+1) ) ];
      else
          if print_previous  % that was the last entry for now
              str = [ str, sprintf('\n};\n\n') ];
              print_previous = 0;
          end
      end
  end
  if print_previous % don't forget to print the closing bracket
      str = [ str, sprintf('\n};\n\n') ];
  end
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


  str = [ str, handle_all_children( handle ) ];


  % -----------------------------------------------------------------------
  % FUNCTION segment_visible
  %
  % Given a series of points 'p', this routines determines which inter-'p'
  % connections are visible in the box given by 'xlim', 'ylim'.
  %
  % -----------------------------------------------------------------------
  function out = segment_visible( p, xlim, ylim )

      n   = size( p, 1 ); % number of points
      out = zeros( n-1, 1 );

      % Find out where (with respect the the box) the points 'p' sit.
      % Consider the documentation for 'boxwhere' to find out about
      % the meaning of the return values.
      boxpos = boxwhere( p, xlim, ylim );

      for k = 1:n-1
          if any(boxpos{k}==1) || any(boxpos{k+1}==1) % one of the two is strictly inside the box
              out(k) = 1;
          elseif any(boxpos{k}==2) || any(boxpos{k+1}==2) % one of the two is strictly outside the box
              % does the segment intersect with any of the four boundaries?
              out(k) =  segments_intersect( [p(k:k+1,1)',xlim(1),xlim(1)], ...   % with the left?
                                            [p(k:k+1,2)',ylim] ) ...
                     || segments_intersect( [p(k:k+1,1)',xlim],  ...             % with the bottom?
                                            [p(k:k+1,2)',ylim(1),ylim(1)] ) ...
                     || segments_intersect( [p(k:k+1,1)',xlim(2),xlim(2)],  ...  % with the right?
                                            [p(k:k+1,2)',ylim] ) ...
                     || segments_intersect( [p(k:k+1,1)',xlim],  ...             % with the top?
                                            [p(k:k+1,2)',ylim(2),ylim(2)] );
          else % both neighboring points lie on the boundary
              % This is kind of tricky as there may be nodes *exactly*
              % in a corner of the domain. boxpos & common_entry handle
              % this, though.
              out(k) =  ~common_entry( boxpos{k},boxpos{k+1} );
          end
      end

  end
  % -----------------------------------------------------------------------
  % END FUNCTION segment_visible
  % -----------------------------------------------------------------------

  % -----------------------------------------------------------------------
  % *** FUNCTION segments_intersect
  % ***
  % *** Checks whether the segments P1--P2 and P3--P4 intersect.
  % *** The x- and y- coordinates of Pi are in x(i), y(i), respectively.
  % ***
  % -----------------------------------------------------------------------
  function out = segments_intersect( x, y );

    % Technically, one writes down the 2x2 equation system to solve the
    %
    %   x1 + lambda (x2-x1)  =  x3 + mu (x4-x3)
    %   y1 + lambda (y2-y1)  =  y3 + mu (y4-y3)
    %
    % for lambda and mu. If a solution exists, check if   0 < lambda,mu < 1.

    det = (x(4)-x(3))*(y(2)-y(1)) - (y(4)-y(3))*(x(2)-x(1));

    out = det;

    if det % otherwise the segments are parallel
	rhs1   = x(3) - x(1);
	rhs2   = y(3) - y(1);
	lambda = ( -rhs1* (y(4)-y(3)) + rhs2* (x(4)-x(3)) ) / det;
	mu     = ( -rhs1* (y(2)-y(1)) + rhs2* (x(2)-x(1)) ) / det;
	out    =   0<lambda && lambda<1 ...
	       &&  0<mu     && mu    <1;
    end

  end
  % -----------------------------------------------------------------------
  % *** END FUNCTION segments_intersect
  % -----------------------------------------------------------------------

end
% =========================================================================
% *** END OF FUNCTION draw_line
% =========================================================================



% =========================================================================
% *** FUNCTION get_line_options
% ***
% *** Gathers the line options.
% ***
% =========================================================================
function line_opts = get_line_options( linestyle, linewidth )

  line_opts = cell(0);

  if ~strcmp(linestyle,'none') && linewidth~=0
      line_opts = [ line_opts,                                      ...
                    sprintf('%s', translate_linestyle(linestyle) ), ...
                    sprintf('line width=%.1fpt', linewidth ) ];
  end

end
% =========================================================================
% *** END FUNCTION get_line_options
% =========================================================================



% =========================================================================
% *** FUNCTION get_marker_options
% ***
% *** Handles the marker properties of a line (or any other) plot.
% ***
% =========================================================================
function draw_options = get_marker_options( h )

  draw_options = cell(0);

  marker = get( h, 'Marker' );

  if ~strcmp( marker, 'none' )
      marker_size = get( h, 'MarkerSize' );
      linestyle   = get( h, 'LineStyle' );
      linewidth   = get( h, 'LineWidth' );

      % In MATLAB, the marker size refers to the edge length of a square
      % (for example) (~diameter), whereas in TikZ the distance of an edge
      % to the center is the measure (~radius). Hence divide by 2.
      tikz_marker_size = translate_markersize( marker, marker_size );
      draw_options = [ draw_options,                                    ...
                       sprintf( 'mark size=%.1fpt', tikz_marker_size ) ];

      mark_options = cell( 0 );
      % make sure that the markers get painted in solid (and not dashed)
      % if the 'linestyle' is not solid (otherwise there is no problem)
      if ~strcmp( linestyle, 'solid' )
          mark_options = [ mark_options, 'solid' ];
      end

      % print no lines
      if strcmp(linestyle,'none') || linewidth==0
          draw_options = [ draw_options, 'only marks' ] ;
      end

      % get the marker color right
      markerfacecolor = get( h, 'MarkerFaceColor' );
      markeredgecolor = get( h, 'MarkerEdgeColor' );
      [ tikz_marker, mark_options ] = translate_marker( marker,         ...
                           mark_options, ~strcmp(markerfacecolor,'none') );
      if ~strcmp(markerfacecolor,'none')
          xcolor = get_color( h, markerfacecolor, 'patch' );
          mark_options = [ mark_options,  sprintf( 'fill=%s', xcolor ) ];
      end
      if ~strcmp(markeredgecolor,'none') && ~strcmp(markeredgecolor,'auto')
          xcolor = get_color( h, markeredgecolor, 'patch' );
          mark_options = [ mark_options, sprintf( 'draw=%s', xcolor ) ];
      end

      % add it all to draw_options
      draw_options = [ draw_options, sprintf( 'mark=%s', tikz_marker ) ];

      if ~isempty( mark_options )
          mo = collapse( mark_options, ',' );
	  draw_options = [ draw_options, [ 'mark options={', mo, '}' ] ];
      end
  end


  % -----------------------------------------------------------------------
  % *** FUNCTION translate_marker
  % -----------------------------------------------------------------------
  function [ tikz_marker, mark_options ] =                                ...
	    translate_marker( matlab_marker, mark_options, facecolor_toggle )

    if( ~ischar(matlab_marker) )
	error( [ ' Function translate_marker:',                           ...
		' Variable matlab_marker is not a string.' ] );
    end

    switch ( matlab_marker )
	case 'none'
	    tikz_marker = '';
	case '+'
	    tikz_marker = '+';
	case 'o'
	    if facecolor_toggle
		tikz_marker = '*';
	    else
		tikz_marker = 'o';
	    end
	case '.'
	    tikz_marker = '*';
	case 'x'
	    tikz_marker = 'x';
	otherwise  % the following markers are only available with PGF's
                   % plotmarks library
	    fprintf( '\nMake sure to load \\usetikzlibrary{plotmarks} in the preamble.\n' );
	    switch ( matlab_marker )

		    case '*'
			    tikz_marker = 'asterisk';

		    case {'s','square'}
		    if facecolor_toggle
				tikz_marker = 'square*';
		    else
			tikz_marker = 'square';
		    end

		    case {'d','diamond'}
		    if facecolor_toggle
				tikz_marker = 'diamond*';
		    else
				tikz_marker = 'diamond';
		    end

		case '^'
		    if facecolor_toggle
				tikz_marker = 'triangle*';
		    else
				tikz_marker = 'triangle';
		    end

		    case 'v'
		    if facecolor_toggle
			tikz_marker = 'triangle*';
		    else
				tikz_marker = 'triangle';
		    end
		    mark_options = [ mark_options, ',rotate=180' ];

		    case '<'
		    if facecolor_toggle
			tikz_marker = 'triangle*';
		    else
				tikz_marker = 'triangle';
		    end
		    mark_options = [ mark_options, ',rotate=270' ];

		case '>'
		    if facecolor_toggle
				tikz_marker = 'triangle*';
		    else
				tikz_marker = 'triangle';
		    end
		    mark_options = [ mark_options, ',rotate=90' ];

		case {'p','pentagram'}
		    if facecolor_toggle
				tikz_marker = 'star*';
		    else
				tikz_marker = 'star';
		    end

		    case {'h','hexagram'}
		    warning( 'matlab2tikz:translate_marker',              ...
			    'MATLAB''s marker ''hexagram'' not available in TikZ. Replacing by ''star''.' );
		    if facecolor_toggle
				tikz_marker = 'star*';
		    else
				tikz_marker = 'star';
		    end

		otherwise
		    error( [ ' Function translate_marker:',               ...
			    ' Unknown matlab_marker ''',matlab_marker,'''.' ] );
	    end
    end

  end
  % -----------------------------------------------------------------------
  % *** END OF FUNCTION translate_marker
  % -----------------------------------------------------------------------


  % -----------------------------------------------------------------------
  % *** FUNCTION translate_markersize
  % ***
  % *** The markersizes of Matlab and TikZ are related, but not equal. This
  % *** is because
  % ***
  % ***  1.) MATLAB uses the MarkerSize property to describe something like
  % ***      the diameter of the mark, while TikZ refers to the 'radius',
  % ***  2.) MATLAB and TikZ take different measures (, e.g., the
  % ***      edgelength of a square vs. the diagonal length of it).
  % ***
  % -----------------------------------------------------------------------
  function tikz_markersize =                                            ...
		   translate_markersize( matlab_marker, matlab_markersize )

    if( ~ischar(matlab_marker) )
	error( 'matlab2tikz:translate_markersize',                      ...
	      'Variable matlab_marker is not a string.' );
    end

    if( ~isnumeric(matlab_markersize) )
	error( 'matlab2tikz:translate_markersize',                      ...
	      'Variable matlab_markersize is not a numeral.' );
    end

    switch ( matlab_marker )
	case 'none'
	    tikz_markersize = [];
	case {'+','o','x','*','p','pentagram','h','hexagram'}
	    tikz_markersize = matlab_markersize / 2;
	case '.'
	    % as documented on the Matlab help pages:
	    %
	    % Note that MATLAB draws the point marker (specified by the '.'
	    % symbol) at one-third the specified size.
	    % The point (.) marker type does not change size when the
	    % specified value is less than 5.
	    %
	    tikz_markersize = matlab_markersize / 2 / 3;
	case {'s','square'}
	    % Matlab measures the diameter, TikZ half the edge length
	    tikz_markersize = matlab_markersize / 2 / sqrt(2);
	case {'d','diamond'}
	    % Matlab measures the width, TikZ the height of the diamond;
	    % the acute angle (top and bottom) is a manually measured
	    % 75 degrees (in TikZ, and Matlab probably very similar);
	    % use this as a base for calculations
	    tikz_markersize = matlab_markersize / 2 / atan( 75/2 *pi/180 );
	case {'^','v','<','>'}
	    % for triangles, matlab takes the height
	    % and tikz the circumcircle radius;
	    % the triangles are always equiangular
	    tikz_markersize = matlab_markersize / 2 * (2/3);
	otherwise
	    error( 'matlab2tikz:translate_markersize',                    ...
		  'Unknown matlab_marker ''%s''.', matlab_marker  );
    end

  end
  % -----------------------------------------------------------------------
  % *** END OF FUNCTION translate_markersize
  % -----------------------------------------------------------------------

end
% =========================================================================
% *** END FUNCTION get_marker_options
% =========================================================================



% =========================================================================
% *** FUNCTION draw_patch
% ***
% *** Draws a 'patch' graphics object (as found in contourf plots, for
% *** example).
% ***
% =========================================================================
function str = draw_patch( handle )

  str = [];

  if ~is_visible( handle )
      return
  end

  % -----------------------------------------------------------------------
  % gather the draw options
  draw_options = cell(0);

  % fill color
  facecolor  = get( handle, 'FaceColor' );
  if ~strcmp( facecolor, 'none' )
      xfacecolor = get_color( handle, facecolor, 'patch' );
      draw_options = [ draw_options,                                    ...
                       sprintf( 'fill=%s', xfacecolor ) ];
  end

  % draw color
  edgecolor = get( handle, 'EdgeColor' );
  linestyle = get( handle, 'LineStyle' );
  if strcmp( linestyle, 'none' ) || strcmp( edgecolor, 'none' )
      draw_options = [ draw_options, 'draw=none' ];
  else
      xedgecolor = get_color( handle, edgecolor, 'patch' );
      draw_options = [ draw_options, sprintf( 'draw=%s', xedgecolor ) ];
  end

  draw_opts = collapse( draw_options, ',' );
  % -----------------------------------------------------------------------


  % MATLAB's patch elements are matrices in which each column represents a
  % a distinct graphical object. Usually there is only one column, but
  % there may be more (-->hist plots, although they are now handled
  % within the barplot framework).
  xdata = get( handle, 'XData' );
  ydata = get( handle, 'YData' );
  m = size(xdata,1);
  n = size(xdata,2);
  for j=1:n
      str = [ str, ...
              sprintf(['\\addplot [',draw_opts,'] coordinates{']) ];
      for i=1:m
          if ~isnan(xdata(i,j)) && ~isnan(ydata(i,j))
              % don't print NaNs
              str = [ str, ...
	              sprintf( ' (%g,%g)', xdata(i,j), ydata(i,j) ) ];
          end
      end
      str = [ str, sprintf('};\n') ];
  end
  str = [ str, sprintf('\n') ];
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  str = [ str, handle_all_children(handle) ];

end
% =========================================================================
% *** END OF FUNCTION draw_patch
% =========================================================================



% =========================================================================
% *** FUNCTION draw_image
% ***
% *** Draws an 'image' graphics object (which is essentially just a matrix
% *** containing the RGB color values for a spot).
% ***
% =========================================================================
function str = draw_image( handle )

  str = [];

  if ~is_visible( handle )
      return
  end

  warning( 'matlab2tikz:drawimage',                                     ...
           [ 'Image data will be plotted upside down as pgfplots does ',...
             'not yet have reverse axes. This functionality is likely ',...
             'to be added in future versions, though.\nIf you are '    ,...
             'feeling adventurous, you can go ahead and get the ',      ...
             'latest CVS version of pgfplots (from sourceforge) and ',  ...
             'insert y={(0,-1cm)} in the axis options.' ] );

  % read x- and y-data
  xlimits = get( handle, 'XData' );
  ylimits = get( handle, 'YData' );

  X = xlimits(1):xlimits(end);
  Y = ylimits(1):ylimits(end);

  cdata = get( handle, 'CData' );

  % draw the thing
  for i = 1:length(Y)
      for j = 1:length(X)
          xcolor = get_color( handle, cdata(i,j,:), 'image' );
          str = [ str, ...
                  sprintf( '\\fill [%s] (axis cs:%g,%g) rectangle (axis cs:%g,%g);\n', ...
                           xcolor,  X(j)-0.5, Y(i)-0.5, X(j)+0.5, Y(i)+0.5  ) ];
      end
  end

end
% =========================================================================
% *** END OF FUNCTION draw_image
% =========================================================================



% =========================================================================
% *** FUNCTION draw_hggroup
% =========================================================================
function str = draw_hggroup( h );

  cl = class( handle(h) );

  switch( cl )
      case 'specgraph.barseries'
	  % hist plots and friends
          str = draw_barseries( h );

      case 'specgraph.stemseries'
	  % stem plots
          str = draw_stemseries( h );

      case 'specgraph.stairseries'
	  % stair plots
          str = draw_stairseries( h );

      case {'specgraph.contourgroup'}
	  % handle all those the usual way
          str = handle_all_children( h );

      case {'specgraph.quivergroup'}
	  % quiver arrows
	  str = draw_quivergroup( h );

      otherwise
	  warning( 'matlab2tikz:draw_hggroup',                          ...
                   'Don''t know class ''%s''. Default handling.', cl );
          str = handle_all_children( h );
  end

end
% =========================================================================
% *** END FUNCTION draw_hggroup
% =========================================================================



% =========================================================================
% *** FUNCTION draw_barseries
% ***
% *** Takes care of plots like the ones produced by MATLAB's hist.
% *** The main pillar is pgfplots's '{x,y}bar' plot.
% ***
% *** NOTE: There is code duplication with 'draw_axes'. Try to get rid of
% ***       that!
% ***
% =========================================================================
function str = draw_barseries( h );

  global matlab2tikz_opts;
  global axis_opts;

  % 'barplot_id' provides a consecutively numbered ID for each
  % barseries plot. This allows for properly handling multiple bars.
  persistent barplot_id
  persistent barplot_total_number
  persistent barwidth
  persistent barshifts

  persistent added_axis_option
  persistent nonbar_plot_present

  str = [];

  % -----------------------------------------------------------------------
  % The bar plot implementation in pgfplots lacks certain functionalities;
  % for example, it can't plot bar plots and non-bar plots in the same
  % axis (while MATLAB can).
  % The following checks if this is the case and cowardly bails out if so.
  % On top of that, the number of bar plots is counted.
  if isempty(barplot_total_number)
      nonbar_plot_present  = 0;
      barplot_total_number = 0;
      parent               = get( h, 'Parent' );
      siblings             = get( parent, 'Children' );
      for k = 1:length(siblings)

          % skip invisible objects
          if ~is_visible(siblings(k))
              continue
          end

          t = get( siblings(k), 'Type' );
          switch t
              case {'line','patch'}
                  nonbar_plot_present = 1;
              case 'text'
                  % this is pretty harmless: don't complain about ordinary text
              case 'hggroup'
                  cl = class(handle(siblings(k)));
	          if strcmp( cl , 'specgraph.barseries' )
	              barplot_total_number = barplot_total_number + 1;
                  else
                      error( 'matlab2tikz:draw_barseries',              ...
                             'Unknown class''%s''.', cl  );
	          end
              otherwise
                  error( 'matlab2tikz:draw_barseries',                  ...
                         'Unknown type ''%s''.', t );
          end
      end
  end
  % -----------------------------------------------------------------------


  xdata = get( h, 'XData' );
  ydata = get( h, 'YData' );

  % init draw_options
  draw_options = cell(0);

  barlayout = get( h, 'BarLayout' );
  switch barlayout
      case 'grouped'
	  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	  % grouped plots
	  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	  groupwidth = 0.8; % MATLAB's default value, see makebars.m

	  % set ID
	  if isempty(barplot_id)
	      barplot_id = 1;
	  else
	      barplot_id = barplot_id + 1;
	  end

	  % ---------------------------------------------------------------
	  % Calculate the width of each bar and the center point shift.
	  % The following is taken from MATLAB (see makebars.m) without
          % the special handling for hist plots or other fancy options.
	  % ---------------------------------------------------------------
	  if isempty( barwidth ) || isempty(barshifts)
	      dx = min( diff(xdata) );
	      groupwidth = dx * groupwidth;

	      % this is the barwidth with no interbar spacing yet
	      barwidth = groupwidth / barplot_total_number;

	      barshifts = -0.5* groupwidth                              ...
			+ ( (0:barplot_total_number-1)+0.5) * barwidth;

	      bw_factor = get( h, 'BarWidth' );
	      barwidth  = bw_factor* barwidth;
	  end
	  % ---------------------------------------------------------------

	  % MATLAB treats shift and width in normalized coordinate units,
          % whereas pgfplots requires physical units (pt,cm,...); hence
          % have the units converted.
          ulength = normalized2physical();
	  draw_options = [ draw_options,                                                ...
                           'ybar',                                                      ...
			   sprintf( 'bar width=%g%s, bar shift=%g%s',                   ...
                                    barwidth             *ulength.value, ulength.unit , ...
                                    barshifts(barplot_id)*ulength.value, ulength.unit  ) ];
	  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	  % end grouped plots
	  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      case 'stacked'
	  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	  % Stacked plots --
          % Add option 'ybar stacked' to the options of the surrounding
          % axis environment (and disallow anything else but stacked
          % plots).
          % Make sure this happens exactly *once*.
          if isempty(added_axis_option) || ~added_axis_option
	      if nonbar_plot_present
		  warning( 'matlab2tikz:draw_barseries',                 ...
			[ 'Pgfplots can''t deal with stacked bar plots', ...
			  ' and non-bar plots in one axis environment.', ...
			  ' There *may* be unexpected results.'         ] );
	      end
	      bw_factor = get( h, 'BarWidth' );
              ulength   = normalized2physical();
              axis_opts = [ axis_opts,                                   ...
                            'ybar stacked',                              ...
                            sprintf( 'bar width=%g%s',                   ...
                                  ulength.value*bw_factor, ulength.unit ) ];
              added_axis_option = 1;
          end
	  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      otherwise
          error( 'matlab2tikz:draw_barseries',                          ...
                 'Don''t know how to handle BarLayout ''%s''.', barlayout );
  end


  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % define edge color
  edgecolor  = get( h, 'EdgeColor' );
  xedgecolor = get_color( h, edgecolor, 'patch' );
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % define face color;
  % quite oddly, this value is not coded in the handle itself, but in its
  % child patch.
  child      = get( h, 'Children' );
  facecolor  = get( child, 'FaceColor');
  xfacecolor = get_color( h, facecolor, 'patch' );
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % gather the draw options
  linestyle = get( h, 'LineStyle' );

  draw_options = [ draw_options, sprintf( 'fill=%s', xfacecolor ) ];
  if strcmp( linestyle, 'none' )
      draw_options = [ draw_options, 'draw=none' ];
  else
      draw_options = [ draw_options, sprintf( 'draw=%s', xedgecolor ) ];
  end
  draw_opts = collapse( draw_options, ',' );
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % plot the thing
  str = [ str, ...
          sprintf( '\\addplot[%s] plot coordinates{', draw_opts ) ];

  for k=1:length(xdata)
      str = [ str, ...
              sprintf( ' (%g,%g)', xdata(k), ydata(k) ) ];
  end
  str = [ str, sprintf(' };\n\n') ];
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

end
% =========================================================================
% *** END FUNCTION draw_barseries
% =========================================================================



% =========================================================================
% *** FUNCTION draw_stemseries
% ***
% *** Takes care of MATLAB's stem plots.
% ***
% *** NOTE: There is code duplication with 'draw_axes'. Try to get rid of
% ***       that!
% ***
% =========================================================================
function str = draw_stemseries( h );

  global matlab2tikz_opts;

  str = [];

  linestyle = get( h, 'LineStyle' );
  linewidth = get( h, 'LineWidth' );
  marker    = get( h, 'Marker' );

  if (    ( strcmp(linestyle,'none') || linewidth==0 )                  ...
       && strcmp(marker,'none') )
      % nothing to plot!
      return
  end

  xdata = get( h, 'XData' );
  ydata = get( h, 'YData' );

  % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
  % deal with draw options
  % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
  color     = get( h, 'Color' );
  plotcolor = get_color( h, color, 'patch' );

  draw_options = [ 'ycomb',                                  ...
                   sprintf( 'color=%s', plotcolor ),         ... % color
                   get_line_options( linestyle, linewidth ), ... % line options
                   get_marker_options( h )                   ... % marker options
                 ];

  % insert draw options
  draw_opts =  collapse( draw_options, ',' );
  % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =



  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % plot the thing
  str = [ str, ...
          sprintf( '\\addplot[%s] plot coordinates{', draw_opts ) ];

  xdata = get( h, 'XData' );
  ydata = get( h, 'YData' );

  for k=1:length(xdata)
      str = [ str, ...
              sprintf( ' (%g,%g)', xdata(k), ydata(k) ) ];
  end
  str = [ str, sprintf(' };\n\n') ];
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

end
% =========================================================================
% *** END FUNCTION draw_stemseries
% =========================================================================



% =========================================================================
% *** FUNCTION draw_stairseries
% ***
% *** Takes care of MATLAB's stairs plots.
% ***
% *** NOTE: There is code duplication with 'draw_axes'. Try to get rid of
% ***       that!
% ***
% =========================================================================
function str = draw_stairseries( h );

  global matlab2tikz_opts;

  str = [];

  linestyle = get( h, 'LineStyle');
  linewidth = get( h, 'LineWidth');
  marker    = get( h, 'Marker');

  if (    ( strcmp(linestyle,'none') || linewidth==0 )                  ...
       && strcmp(marker,'none') )
      return
  end

  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % deal with draw options
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  color     = get( h, 'Color' );
  plotcolor = get_color( h, color, 'patch' );

  draw_options = [ 'const plot',                             ...
                   sprintf( 'color=%s', plotcolor ),         ... % color
                   get_line_options( linestyle, linewidth ), ... % line options
                   get_marker_options( h )                   ... % marker options
                 ];

  % insert draw options
  draw_opts =  collapse( draw_options, ',' );
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % plot the thing
  str = [ str, ...
          sprintf( '\\addplot[%s] plot coordinates{', draw_opts ) ];

  xdata = get( h, 'XData' );
  ydata = get( h, 'YData' );

  for k=1:length(xdata)
      str = [ str, ...
              sprintf( ' (%g,%g)', xdata(k), ydata(k) ) ];
  end
  str = [ str, sprintf(' };\n\n') ];
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

end
% =========================================================================
% *** END FUNCTION draw_stairseries
% =========================================================================



% =========================================================================
% *** FUNCTION draw_quivergroup
% ***
% *** Takes care of MATLAB's quiver plots.
% ***
% =========================================================================
function str = draw_quivergroup( h );

  global matlab2tikz_opts;

  str = [];

  xdata = get( h, 'XData' );
  ydata = get( h, 'YData' );
  udata = get( h, 'UData' );
  vdata = get( h, 'VData' );

  m = size( xdata, 1 );
  n = size( xdata, 2 );

  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % Do autoscaling. The following procedure can be found in MATLAB's
  % quiver.m
  autoscale = get( h, 'AutoScale' );
  if strcmp( autoscale, 'on' )

      scalefactor = get( h, 'AutoScaleFactor' );

      % Get average spacing in x- and y-direction.
      % -- This assumes that when xdata, ydata are indeed 2D entities, they
      %    really repeat the same row (column) m (n) times. Hence take only
      %    the first.
      avx = diff([min(xdata(1,:)) max(xdata(1,:))])/m;
      avy = diff([min(ydata(:,1)) max(ydata(:,1))])/n;
      av  = avx.^2 + avy.^2; % length of the average box diagonal

      % get the maximal length of a scaled arrow
      if av>0
	  len = sqrt( (udata.^2 + vdata.^2)/av );
	  maxlen = max(len(:));
      else
	  maxlen = 0;
      end

      if maxlen>0
	  scalefactor = scalefactor*0.9 / maxlen;
      else
	  scalefactor = scalefactor*0.9;
      end
      udata = udata*scalefactor;
      vdata = vdata*scalefactor;      
  end
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % gather the arrow options
  showarrowhead = get( h, 'ShowArrowHead' );
  linestyle     = get( h, 'LineStyle' );
  linewidth     = get( h, 'LineWidth' );

  if ( strcmp(linestyle,'none') || linewidth==0 )  && ~showarrowhead
      return
  end

  arrow_opts = cell(0);
  if showarrowhead
      arrow_opts = [ arrow_opts, '->' ];
  else
      arrow_opts = [ arrow_opts, '-' ];
  end

  color      = get( h, 'Color');
  arrowcolor = get_color( h, color, 'patch' );
  arrow_opts = [ arrow_opts,                               ...
                 sprintf( 'color=%s', arrowcolor ),        ... % color
                 get_line_options( linestyle, linewidth ), ... % line options
               ];

  arrow_options = collapse( arrow_opts, ',' );
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  for i=1:m
      for j=1:n
          str = [ str, ...
                  sprintf( '\\addplot [%s] coordinates{ (%g,%g) (%g,%g) };\n',...
                           arrow_options,                              ...
                           xdata(i,j)           , ydata(i,j)        ,  ...
                           xdata(i,j)+udata(i,j), ydata(i,j)+vdata(i,j) ) ];
      end
  end
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

end
% =========================================================================
% *** END FUNCTION draw_quivergroup
% =========================================================================



% =========================================================================
% *** FUNCTION draw_colorbar
% =========================================================================
function str = draw_colorbar( handle )

  str = [];

  if ~is_visible( handle )
      return
  end

%    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%    % Try to find the parent axes of this colorbar for height/width info.
%    % Unfortunately, all axes in a figure (and hence colorbar, too) are
%    % siblings, and there doesn't _seem_ to be info about the refering axes
%    % in the colorbar axes.
%    % Hence, go back to parent and search for the (one?) non-colorbar axes
%    % pair.
%    c = get( get(handle,'Parent'), 'Children' ); % siblings of handle
%    parent = 0;
%    for k=1:size(c)
%        if  strcmp( get(c(k),'Type'), 'axes'     ) && ...
%           ~strcmp( get(c(k),'Tag' ), 'Colorbar' )
%            parent = c(k);
%            break
%        end
%    end
%  
%    if ~parent
%        warning( 'matlab2tikz:draw_colorbar',                             ...
%                 'Unable to find the colorbar''s parental axes. Skip.' );
%        return;
%    end
%  
%    % get the size of 'parent'
%    dim = get_axes_dimensions( parent );
%    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  % The dimensions returned by  'get_axes_dimensions' are not entirely
  % correct: When looking closely, one will see that the colorbar actually
  % (very slightly) overshoots the size of its parental axis.
  % For now, leave it like this as the overshoot is really small
  dim = get_axes_dimensions( handle );

  % get the upper and lower limit of the colorbar
  clim = caxis;

  % begin collecting axes options
  cbar_options = cell( 0 );
  cbar_options = [ cbar_options,                                        ...
                   'at={(colorbar anchor)}',                            ...
                   'axis on top' ];

  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % set position, ticks etc. of the colorbar
  loc = get( handle, 'Location' );
  switch loc
      case { 'North', 'South', 'East', 'West' }
          warning( 'matlab2tikz:draw_colorbar',                         ...
                   'Don''t know how to deal with inner colorbars yet.' );
          return;

      case {'NorthOutside','SouthOutside'}
%            dim.y = dim.x / ratio;
          cbar_options = [ cbar_options,                                ...
	                   sprintf( 'width=%g%s, height=%g%s',          ...
                                     dim.x, dim.unit, dim.y, dim.unit ),...
                           'scale only axis',                           ...
                           sprintf( 'xmin=%g, xmax=%g', clim ),         ...
                           sprintf( 'ymin=%g, ymax=%g', [0,1] )         ...
                         ];

          if strcmp( loc, 'NorthOutside' )
              anchorparent = 'above north west';
              cbar_options = [ cbar_options,                            ...
                               'anchor=south west',                     ...
                               'xticklabel pos=right, ytick=\\empty' ];
                               % we actually wanted to set pos=top here,
                               % but pgfplots doesn't support that yet.
                               % pos=right does the same thing, really.
          else
              anchorparent = 'below south west';
              cbar_options = [ cbar_options,                            ...
                               'anchor=north west',                     ...
                               'xticklabel pos=left, ytick=\\empty' ];
                               % we actually wanted to set pos=bottom here,
                               % but pgfplots doesn't support that yet. 
                               % pos=left does the same thing, really.
          end

      case {'EastOutside','WestOutside'}
          cbar_options = [ cbar_options,                                ...
	                   sprintf( 'width=%g%s, height=%g%s',          ...
                                     dim.x, dim.unit, dim.y, dim.unit ),...
                           'scale only axis',                           ...
                           sprintf( 'xmin=%g, xmax=%g', [0,1] ),        ...
                           sprintf( 'ymin=%g, ymax=%g', clim )          ...
                         ];
          if strcmp( loc, 'EastOutside' )
               anchorparent = 'right of south east';
               cbar_options = [ cbar_options,                           ...
                                'anchor=south west',                    ...
                                'xtick=\\empty, yticklabel pos=right' ];
           else
               anchorparent = 'left of south west';
               cbar_options = [ cbar_options,                           ...
                                'anchor=south east',                    ...
                                'xtick=\\empty, yticklabel pos=left' ];
           end

      otherwise
          error( 'draw_colorbar: Unknown ''Location'' %s.', loc )
  end
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % get ticks along with the labels
  [ ticks, ticklabels ] = get_ticks( handle );
  if ~isempty( ticks.x )
      cbar_options = [ cbar_options,                                    ...
                       sprintf( 'xtick={%s}', ticks.x ) ];
  end
  if ~isempty( ticklabels.x )
      cbar_options = [ cbar_options,                                    ...
                       sprintf( 'xticklabels={%s}', ticklabels.x ) ];
  end
  if ~isempty( ticks.y )
      cbar_options = [ cbar_options,                                    ...
                       sprintf( 'ytick={%s}', ticks.y ) ];
  end
  if ~isempty( ticklabels.y )
      cbar_options = [ cbar_options,                                    ...
                       sprintf( 'yticklabels={%s}', ticklabels.y ) ];
  end
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % introduce an anchor coordinate;
  % as an extra, one could add a ++(5mm,0) or something like that to increase
  % the space between the colorbar and the main plot
  str = [ str, ...
          sprintf( [ '\n\n%% introduce named coordinate:\n',            ... 
                     '\\path (main plot.%s)',                           ...
                     ' coordinate (colorbar anchor);\n' ], anchorparent ) ];
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % actually begin drawing the thing
  str = [ str, ...
          sprintf( '\n%% draw the colorbar\n' ) ];
  cbar_opts = collapse( cbar_options, ',\n' );
  str = [ str, ...
          sprintf( [ '\\begin{axis}[\n', cbar_opts, '\n]\n' ] ) ];
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  % get the colormap
  cmap = colormap;

  cbar_length = clim(2) - clim(1);

  m = size( cmap, 1 );
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % plot tiny little badges for the respective colors
  for i=1:m
      badgecolor = rgb2tikzcol( cmap(i,:) );

      switch loc
          case {'NorthOutside','SouthOutside'}
              x1 = clim(1) + cbar_length/m *(i-1);
              x2 = clim(1) + cbar_length/m *i;
              y1 = 0;
              y2 = 1; 
          case {'WestOutside','EastOutside'}
              x1 = 0;
              x2 = 1;
              y1 = clim(1) + cbar_length/m *(i-1);
              y2 = clim(1) + cbar_length/m *i; 
      end
      str = [ str, ...
              sprintf( '\\addplot [fill=%s,draw=none] coordinates{ (%g,%g) (%g,%g) (%g,%g) (%g,%g) };\n', ...
                         badgecolor, x1, y1, x2, y1, x2, y2, x1, y2    ) ];
  end
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  % do _not_ handle colorbar's children

  % close & good-bye
  str = [ str, sprintf('\\end{axis}\n\n') ];

end
% =========================================================================
% *** END FUNCTION draw_colorbar
% =========================================================================



% =========================================================================
% *** FUNCTION get_color
% ***
% *** Handles MATLAB colors and makes them available to TikZ.
% *** This includes translation of the color value as well as explicit
% *** definition of the color if it is not available in TikZ by default.
% ***
% *** The variable 'mode' essentially determines what format 'color' can
% *** have. Possible values are (as strings) 'patch' and 'image'.
% ***
% =========================================================================
function xcolor = get_color( handle, color, mode )

  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % grab rgb value
  switch mode
      case 'patch'
          rgbcol = patchcolor2rgb ( color, handle );
      case 'image'
          rgbcol = imagecolor2rgb ( color, handle );
      otherwise
          error( [ 'matlab2tikz:get_color',                        ...
                   'Argument ''mode'' has illegal value ''%s''' ], ...
                 mode );
  end
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  % ... and make sure a xcolor value is returned
  xcolor = rgb2tikzcol( rgbcol );

end
% =========================================================================
% *** END FUNCTION get_color
% =========================================================================



% =========================================================================
% *** FUNCTION rgb2tikzcol
% ***
% *** This function takes and RGB coded color as input and returns a string
% *** describing the color that can be used in the TikZ file.
% *** It checks if the color is predefined (by xcolor.sty) or if it needs
% *** to be custom defined. It keeps all the self-defined colors in
% *** 'neededRGBColors' to avoid redundant definitions.
% ***
% =========================================================================
function xcolor = rgb2tikzcol( rgbcol )

  global tol
  % Remember the color rbgvalues which will need to be redefined.
  % Each row of 'neededRGBColors' contains the RGB values of a needed
  % color.
  global neededRGBColors

  xcolor = rgb2xcolor( rgbcol );
  if isempty( xcolor )
      if isempty(neededRGBColors) || length(neededRGBColors)==0
          % initialize the matrix
          neededRGBColors = rgbcol;
          xcolor          = 'mycolor1';
      else

          % check if the color has appeared before
          k0 = 0;
          n  = size(neededRGBColors,1);
          for k = 1:size(neededRGBColors,1)
              if norm(neededRGBColors(k,:)-rgbcol)<tol
                  k0 = k;
                  break
              end
          end

          if k0
              % take that former color
              xcolor = sprintf( 'mycolor%d', k0 );
          else
              % otherwise have a new one defined
              neededRGBColors = [neededRGBColors; rgbcol];
              xcolor = sprintf( 'mycolor%d', n+1 );
          end

      end

  end

end
% =========================================================================
% *** FUNCTION rgb2tikzcol
% =========================================================================



% =========================================================================
% *** FUNCTION patchcolor2rgb
% ***
% *** Transforms a color of the edge or the face of a patch to a 1x3 rgb 
% *** color vector.
% ***
% =========================================================================
function rgbcolor = patchcolor2rgb ( color, imagehandle )

  % check if the color is straight given in rgb
  % -- notice that we need the extra NaN test with respect to the QUIRK
  %    below
  if ( isreal(color) && length(color)==3 && ~any(isnan(color)) )
      % everything allright: bail out
      rgbcolor = color;
      return
  end

  switch color
      case 'flat'
          % look for CData at different places
	  cdata = get( imagehandle, 'CData' );
          if isempty(cdata) || ~isnumeric(cdata)
	      c     = get( imagehandle, 'Children' );
	      cdata = get( c, 'CData' );
          end

	  % QUIRK: With contour plots (not contourf), cdata will be a vector of
	  %        equal values, except the last one which is a NaN. To work 
	  %        around this oddity, just take the first entry.
	  %        With barseries plots, data has been observed to return a
	  %        *matrix* with all equal entries.
	  cdata = cdata( 1, 1 );

	  rgbcolor = cdata2rgb( cdata, imagehandle );

      case 'none'
	  error( [ 'matlab2tikz:anycolor2rgb',                       ...
		   'Color model ''none'' not allowed here. ',        ...
		   'Make sure this case gets intercepted before.' ] );

      otherwise
	  error( [ 'matlab2tikz:anycolor2rgb',                          ...
		  'Don''t know how to handle the color model ''%s''.' ],  ...
		  color );
  end

end
% =========================================================================
% *** END OF FUNCTION patchcolor2rgb
% =========================================================================



% =========================================================================
% *** FUNCTION imagecolor2rgb
% ***
% *** Transforms a color in image color format to a 1x3 rgb color vector.
% ***
% =========================================================================
function rgbcolor = imagecolor2rgb ( color, imagehandle )

  % check if the color is straight given in rgb
  if ( isreal(color) && length(color)==3 )
      rgbcolor = color;
      return
  end

  % -- no? then it *must* be a single cdata value
  rgbcolor = cdata2rgb( color, imagehandle );

end
% =========================================================================
% *** END OF FUNCTION imagecolor2rgb
% =========================================================================



% =========================================================================
% *** FUNCTION cdata2rgb
% ***
% *** Transforms a color in CData format to a 1x3 rgb color vector.
% ***
% =========================================================================
function rgbcolor = cdata2rgb ( cdata, imagehandle )

  global matlab2tikz_opts;

  if ~isnumeric(cdata)
      error( 'matlab2tikz:cdata2rgb',                        ...
	     [ 'Don''t know how to handle cdata ''',cdata,'''.' ] )
  end

  fighandle  = matlab2tikz_opts.gcf;
  axeshandle = matlab2tikz_opts.gca;

  colormap = get( fighandle, 'ColorMap' );

  % -----------------------------------------------------------------------
  % For the following, see, for example, the MATLAB help page for 'image',
  % section 'Image CDataMapping'.
  switch get( imagehandle, 'CDataMapping' )
      case 'scaled'
	  % need to scale within clim
	  % see MATLAB's manual page for caxis for details
	  clim = get( axeshandle, 'clim' );
	  m = size( colormap, 1 );
	  if cdata<=clim(1)
	      colorindex = 1;
	  elseif cdata>=clim(2)
	      colorindex = m;
	  else
	      colorindex = fix( (cdata-clim(1))/(clim(2)-clim(1)) *m ) ...
			 + 1;
	  end

      case 'direct'
	  % direct index
	  colorindex = cdata;

      otherwise
	    error( [ 'matlab2tikz:anycolor2rgb',                ...
		     'Unknown CDataMapping ''%s''.' ],          ...
		     cdatamapping );
  end
  % -----------------------------------------------------------------------

  % finally, return the rgb value
  rgbcolor = colormap( colorindex, : );

end
% =========================================================================
% *** END OF FUNCTION cdata2rgb
% =========================================================================



% =========================================================================
% *** FUNCTION get_legend_opts
% =========================================================================
function lopts = get_legend_opts( handle )

  if ~is_visible( handle )
      return
  end

  entries = get( handle, 'String' );

  n = length( entries );

  lopts = cell( 0 );

  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % handle legend entries
  if n
      for k=1:n
          % escape all lenged entries to math mode for now
          % -- this is later to be removed
          entries{k} = [ '$', entries{k}, '$' ];
      end

      lopts = [ lopts,                                                  ...
                [ 'legend entries={', collapse(entries,','), '}' ] ];
  end
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % handle legend location
  loc = get( handle, 'Location' );
  switch loc
      case 'NorthEast'
          % don't append any options in this (default) case
      case 'NorthWest'
          lopts = [ lopts,                                              ...
                    'legend style={at={(0.03,0.97)},anchor=north west}' ]; 
      case 'SouthWest'
          lopts = [ lopts,                                              ...
                    'legend style={at={(0.03,0.03)},anchor=south west}' ];
      case 'SouthEast'
          lopts = [ lopts,                                              ...
                    'legend style={at={(0.97,0.03)},anchor=south east}' ];
      case 'North'
          lopts = [ lopts,                                              ...
                    'legend style={at={(0.5,0.97)},anchor=north}' ];
      case 'East'
          lopts = [ lopts,                                              ...
                    'legend style={at={(0.97,0.5)},anchor=east}' ];
      case 'South'
          lopts = [ lopts,                                              ...
                    'legend style={at={(0.5,0.03)},anchor=south}' ];
      case 'West'
          lopts = [ lopts,                                              ...
                    'legend style={at={(0.03,0.5)},anchor=west}' ];
      otherwise
	  warning( 'matlab2tikz:get_legend_opts',                       ...
                   [ ' Function get_legend_opts:',                      ...
		     ' Unknown legend location ''',loc,''               ...
                     '. Choosing default.' ] );
  end
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

end
% =========================================================================
% *** FUNCTION get_legend_opts
% =========================================================================



% =========================================================================
% *** FUNCTION get_ticks
% ***
% *** Return axis tick marks pgfplot style. Nice: Tick lengths and such
% *** details are taken care of by pgfplot.
% ***
% =========================================================================
function [ ticks, ticklabels ] = get_ticks( handle )

  global tol

  xtick      = get( handle, 'XTick' );
  xticklabel = get( handle, 'XTickLabel' );

  ytick      = get( handle, 'YTick' );
  yticklabel = get( handle, 'YTickLabel' );

  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % set xticks + labels
  ticks.x = collapse( num2cell(xtick), ',' );

  % sometimes ticklabels are cells, sometimes plain arrays
  % -- unify this to cells
  if ischar( xticklabel )
      xticklabel = strtrim( mat2cell(xticklabel,                        ...
                          ones(size(xticklabel,1),1),size(xticklabel,2)) );
  end

  % if the axis is logscaled, MATLAB does not store the labels, but the
  % exponents to 10
  if strcmp( get(handle,'XScale'),'log' )
      for k = 1:length(xticklabel)
          if isnumeric( xticklabel{k} )
              str = num2str( xticklabel{k} );
          else
              str = xticklabel{k};
          end
          xticklabel{k} = sprintf( '$10^{%s}$', str );
      end
  end

  % check if ticklabels are really necessary (and not already covered by
  % the tick values themselves)
  plot_labels_necessary = 0;
  for k = 1:min(length(xtick),length(xticklabel))
       % Don't use str2num here as then, literal strings as 'pi' get
       % legally transformed into 3.14... and the need for an explicit
       % label will not be recognized. str2double returns a NaN for 'pi'.
       s = str2double( xticklabel{k} );
       if isnan(s)  ||  abs(xtick(k)-s) > tol
           plot_labels_necessary = 1;
           break
       end
  end

  if plot_labels_necessary
      ticklabels.x = collapse( xticklabel, ',' );
  else
      ticklabels.x = [];
  end
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  % set yticks + labels
  ticks.y = collapse( num2cell(ytick), ',' );

  if ischar( yticklabel )
      yticklabel = strtrim( mat2cell(yticklabel,                        ...
                          ones(size(yticklabel,1),1),size(yticklabel,2)) );
  end

  % if the axis is logscaled, MATLAB does not store the labels, but the
  % exponents to 10
  if strcmp( get(handle,'YScale'),'log' )
      for k = 1:length(yticklabel)
          if isnumeric( yticklabel{k} )
              str = num2str( yticklabel{k} );
          else
              str = yticklabel{k};
          end
          yticklabel{k} = sprintf( '$10^{%s}$', str );
      end
  end

  % check if ticklabels are really necessary (and not already covered by
  % the tick values themselves)
  plot_labels_necessary = 0;
  for k = 1:min(length(ytick),length(yticklabel))
       % Don't use str2num here as then, literal strings as 'pi' get
       % legally transformed into 3.14... and the need for an explicit
       % label will not be recognized. str2double returns a NaN for 'pi'.
       s = str2double( yticklabel{k} );
       if isnan(s)  ||  abs(ytick(k)-s) > tol
           plot_labels_necessary = 1;
           break
       end
  end

  if plot_labels_necessary
      ticklabels.y = collapse( yticklabel, ',' );
  else
      ticklabels.y = [];
  end
  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

end
% =========================================================================
% *** END FUNCTION get_ticks
% =========================================================================



% =========================================================================
% *** FUNCTION draw_text
% =========================================================================
function str = draw_text( handle )

  str = [];

  if ~is_visible( handle )
      return
  end

  text = get( handle, 'String' );
  if isempty(strtrim(text))
      return
  end
  
  str = [ str, sprintf( fid, '%% Draw a text handle\n' ) ];
  text = regexprep( text, '\', '\\' );

  position = get( handle, 'Position' );

  node_options = '';
  rotate = get( handle, 'Rotation' );
  if rotate~=0
      node_options = [node_options, sprintf(',rotate=%.1f',rotate) ];
  end

  % we're not really accurate here: stricly speaking, bottom and baseline
  % alignments are different; not being handled, yet
  valign = get( handle, 'VerticalAlignment' );
  switch valign
      case {'bottom','baseline'}
	      node_options = [node_options, sprintf(',anchor=south') ];
      case {'top','cap'}
	      node_options = [node_options, sprintf(',anchor=north') ];
      case 'middle'
      otherwise
	      warning( 'matlab2tikz:draw_text',                         ...
                  'Don''t know what VerticalAlignment %s means.', valign );
  end
  
  halign = get( handle, 'HorizontalAlignment' );
  switch halign
      case 'left'
	      node_options = [node_options, sprintf(',anchor=west') ];
      case 'right'
	      node_options = [node_options, sprintf(',anchor=east') ];
      case 'center'
      otherwise
          warning( 'matlab2tikz:draw_text',                             ...
	        'Don''t know what HorizontalAlignment %s means.', halign );
  end

  str = [ str, ...
          sprintf( '\\draw (%g,%g) node[%s] {$%s$};\n\n',               ...
                   position(1), position(2), node_options, text ) ];

  str = [ str, ...
          handle_all_children( handle ) ];
  
end
% =========================================================================
% *** END OF FUNCTION draw_text
% =========================================================================



% =========================================================================
% *** FUNCTION translate_text
% ***
% *** This function converts MATLAB text strings to valid LaTeX ones.
% ***
% =========================================================================
function newstr = translate_text( handle )

  str = get( handle, 'String' );

  int = get( handle, 'Interpreter' );
  switch int
      case 'none'
          newstr = str;
          newstr = strrep( newstr, '''', '\''''' );
          newstr = strrep( newstr, '%' , '%%'    );
          newstr = strrep( newstr, '\' , '\\'    );
      case {'tex','latex'}
          newstr = str;
      otherwise
          error( 'matlab2tikz:translate_text',                          ...
                 'Unknown text interpreter ''%s''.', int )
  end

end
% =========================================================================
% *** FUNCTION translate_text
% =========================================================================



% =========================================================================
% *** FUNCTION translate_linestyle
% =========================================================================
function tikz_linestyle = translate_linestyle( matlab_linestyle )
  
  if( ~ischar(matlab_linestyle) )
      error( [ ' Function translate_linestyle:',                        ...
               ' Variable matlab_linestyle is not a string.' ] );
  end

  switch ( matlab_linestyle )
      case 'none'
          tikz_linestyle = '';
      case '-'
          tikz_linestyle = 'solid';
      case '--'
          tikz_linestyle = 'dashed';
      case ':'
          tikz_linestyle = 'dotted';           
      case '-.'
          tikz_linestyle = 'dash pattern=on 1pt off 3pt on 3pt off 3pt';
      otherwise
	  error( [ ' Function translate_linestyle:',                    ...
		   ' Unknown matlab_linestyle ''',matlab_linestyle,'''.']);
  end
end
% =========================================================================
% *** END OF FUNCTION translate_linestyle
% =========================================================================



% =========================================================================
% *** FUNCTION rgb2xcolor
% ***
% *** Translates and rgb value to a xcolor literal -- if possible!
% *** If not, it returns the empty string.
% *** This allows for a cleaner output in cases where predefined colors are
% *** being used.
% ***
% *** Take a look at xcolor.sty for the color definitions.
% ***
% =========================================================================
function xcolor_literal = rgb2xcolor( rgb )

  if isequal( rgb, [1,0,0] )
      xcolor_literal = 'red';
  elseif isequal( rgb, [0,1,0] )
      xcolor_literal = 'green';
  elseif isequal( rgb, [0,0,1] )
      xcolor_literal = 'blue';
  elseif isequal( rgb, [0.75,0.5,0.25] )
      xcolor_literal = 'brown';
  elseif isequal( rgb, [0.75,1,0] )
      xcolor_literal = 'lime';
  elseif isequal( rgb, [1,0.5,0] )
      xcolor_literal = 'orange';
  elseif isequal( rgb, [1,0.75,0.75] )
      xcolor_literal = 'pink';
  elseif isequal( rgb, [0.75,0,0.25] )
      xcolor_literal = 'pink';
  elseif isequal( rgb, [0.75,0,0.25] )
      xcolor_literal = 'purple';
  elseif isequal( rgb, [0,0.5,0.5] )
      xcolor_literal = 'teal';
  elseif isequal( rgb, [0.5,0,0.5] )
      xcolor_literal = 'violet';
  elseif isequal( rgb, [0,1,1] )
      xcolor_literal = 'cyan';
  elseif isequal( rgb, [1,0,1] )
      xcolor_literal = 'magenta';
  elseif isequal( rgb, [1,1,0] )
      xcolor_literal = 'yellow';
  elseif isequal( rgb, [0.5,0.5,0] )
      xcolor_literal = 'olive';
  elseif isequal( rgb, [0,0,0] )
      xcolor_literal = 'black';
  elseif isequal( rgb, [0.5,0.5,0.5] )
      xcolor_literal = 'gray';
  elseif isequal( rgb, [0.75,0.75,0.75] )
      xcolor_literal = 'lightgray';
  elseif isequal( rgb, [1,1,1] )
      xcolor_literal = 'white';
  else
      xcolor_literal = '';
  end

end
% =========================================================================
% *** FUNCTION rgb2xcolor
% =========================================================================



% =========================================================================
% *** FUNCTION collapse
% ***
% *** This function collapses a cell of strings to a single string (with a
% *** given delimiter inbetween two strings, if desired).
% ***
% *** Example of usage:
% ***              collapse( cellstr, ',' )
% ***
% =========================================================================
function newstr = collapse( cellstr, delimiter )

  if length(cellstr)<1
     newstr = [];
     return
  end

  if isnumeric( cellstr{1} )
      newstr = my_num2str( cellstr{1} );
  else
      newstr = cellstr{1};
  end

  for k = 2:length( cellstr )
      if isnumeric( cellstr{k} )
          str = my_num2str( cellstr{k} );
      else
          str = cellstr{k};
      end
      newstr = [ newstr, delimiter, str ];
  end

end
% =========================================================================
% *** END FUNCTION collapse
% =========================================================================



% =========================================================================
% *** FUNCTION get_axislabels
% =========================================================================
function axislabels = get_axislabels( handle )

  axislabels.x = get( get( handle, 'XLabel' ), 'String' );
  axislabels.y = get( get( handle, 'YLabel' ), 'String' );

end
% =========================================================================
% *** END FUNCTION get_axislabels
% =========================================================================



% =========================================================================
% *** FUNCTION my_num2str
% ***
% *** Returns a number to a string in a *short* form.
% ***
% =========================================================================
function str = my_num2str( num )

  if ~isnumeric( num )
      error( 'num2str_short: Invalid input.' )
  end

  str = num2str( num, '%g' );

end
% =========================================================================
% *** END FUNCTION my_num2str
% =========================================================================



%  % =========================================================================
%  % *** FUNCTION get_axes_scaling
%  % ***
%  % *** Returns the scaling of the axes.
%  % ***
%  % =========================================================================
%  function scaling = get_axes_scaling( handle )
%  
%    % arbitrarily chosen: the longer edge of the plot has length 50(mm)
%    % (the other is calculated according to the aspect ratio)
%    longer_edge = 50;
%  
%    xyscaling = daspect;
%  
%    xlim = get( handle, 'XLim' );
%    ylim = get( handle, 'YLim' );
%  
%    % [x,y]length are the actual lengths of the axes in some obscure unit
%    xlength = (xlim(2)-xlim(1)) / xyscaling(1);
%    ylength = (ylim(2)-ylim(1)) / xyscaling(2);
%  
%    if ( xlength>=ylength )
%        baselength = xlength;
%    else
%        baselength = ylength;
%    end
%    
%    % one of the quotients cancels to longer_edge
%    physical_length.x = longer_edge * xlength / baselength;
%    physical_length.y = longer_edge * ylength / baselength;
%  
%    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%    % For log-scaled axes, the pgfplot scaling means scaling powers of exp(1)
%    % (see pgfplot manual p. 55). Hence, take the natural logarithm in those
%    % cases.
%    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%    xscale  = get( handle, 'XScale' );
%    yscale  = get( handle, 'YScale' );
%    is_xlog = strcmp( xscale, 'log' );
%    is_ylog = strcmp( yscale, 'log' );
%    if is_xlog
%        q.x = log( xlim(2)/xlim(1) );
%    else
%        q.x = xlim(2) - xlim(1);
%    end
%  
%    if is_ylog
%        q.y = log( ylim(2)/ylim(1) );
%    else
%        q.y = ylim(2) - ylim(1);
%    end
%    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%  
%    % finally, set the scaling
%    scaling.x = sprintf( '%gmm', physical_length.x / q.x );
%    scaling.y = sprintf( '%gmm', physical_length.y / q.y );
%  
%  
%    % The only way to reliably get the aspect ratio of the axes is
%    % the 'Position' property. Neither 'DataAspectRatio' nor
%    % 'PlotBoxAspectRatio' seem to always  yield the correct ratio.
%    % Critital are for example figures with subplots.
%  %    position = get( handle, 'Position' )
%  %  
%  %    xscaling = 1;
%  %    yscaling = position(4)/position(3) * (xlim(2)-xlim(1))/(ylim(2)-ylim(1));
%  %  
%  %    % normalize: make sure the smaller side is always 1(cm)
%  %    xscaling = xscaling/min(xscaling,yscaling);
%  %    yscaling = yscaling/min(xscaling,yscaling);
%  
%    % well, it seems that MATLAB's very own print functions doesn't preserve
%    % aspect ratio when printing -- we do! hence the difference in the output
%  %    dar = get( handle, 'DataAspectRatio' );
%  %    xyscaling = 1 ./ dar;
%  
%  end
%  % =========================================================================
%  % *** END FUNCTION get_axes_scaling
%  % =========================================================================



% =========================================================================
% *** FUNCTION get_axes_dimensions
% ***
% *** Returns the physical dimension of the axes.
% ***
% =========================================================================
function dimension = get_axes_dimensions( handle )

  daspectmode = get( handle, 'DataAspectRatioMode' );
  position    = get( handle, 'Position' );
  units       = get( handle, 'Units' );

  if strcmp( daspectmode, 'auto' )
      % The plot will use the full size of the current figure.,

      if strcmp( units, 'normalized' )

	  % The dpi is needed to associate the size on the screen (in pixels)
          % to the physical size of the plot (on a pdf, for example).
	  % Unfortunately, MATLAB doesn't seem to be able to always make a
          % good guess about the current DPI (a bug is filed for this on
          % mathworks.com).
	  dpi = get( 0, 'ScreenPixelsPerInch' );

          dimension.unit = 'in';
          figuresize = get( gcf, 'Position' );

          dimension.x = position(3) * figuresize(3) / dpi;
          dimension.y = position(4) * figuresize(4) / dpi;

      else % assume that TikZ knows the unit (in, cm,...)
          dimension.unit = units;
          dimension.x    = position(3);
          dimension.y    = position(4);
      end

  else % strcmp( daspectmode, 'manual' )

      % When daspect was manually set, stick to it.
      % This is achieved here by explicitly determining the x-axis size
      % and adjusting the y-axis size based on this length.

      if strcmp( units, 'normalized' )
	  % The dpi is needed to associate the size on the screen (in pixels)
          % to the physical size of the plot (on a pdf, for example).
	  % Unfortunately, MATLAB doesn't seem to be able to always make a
          % good guess about the current DPI (a bug is filed for this on
          % mathworks.com).
	  dpi = get( 0, 'ScreenPixelsPerInch');

          dimension.unit = 'in';
          figuresize = get( gcf, 'Position' );

          dimension.x = position(3) * figuresize(3) / dpi;

      else % assume that TikZ knows the unit
          dimension.unit = units;
          dimension.x    = position(3);
      end

      % set y-axis length
      xlim        = get ( handle, 'XLim' );
      ylim        = get ( handle, 'YLim' );
      aspectRatio = get ( handle, 'DataAspectRatio' ); % = daspect

      % Actually, we'd have
      %
      %    xlength = (xlim(2)-xlim(1)) / aspectRatio(1);
      %    ylength = (ylim(2)-ylim(1)) / aspectRatio(2);
      %
      % but as xlength is scaled to a fixed 'dimension.x', 'dimension.y'
      % needs to be rescaled accordingly.
      dimension.y = dimension.x                                          ...
                  * aspectRatio(1)    / aspectRatio(2)                   ...
                  * (ylim(2)-ylim(1)) / (xlim(2)-xlim(1));

  end

%    % arbitrarily chosen: maximal width and height (in mm)
%    % this seems to be pretty much what the PDF/EPS print functions in MATLAB
%    % do
%    maxwidth  = 150;
%    maxheight = 120;
%  
%    xyscaling = daspect;
%  %    xyscaling = get( handle, 'DataAspectRatio' )
%  
%    xlim = get( handle, 'XLim' );
%    ylim = get( handle, 'YLim' );
%  
%    % {x,y}length are the actual lengths of the axes in some obscure unit
%    xlength = (xlim(2)-xlim(1)) / xyscaling(1);
%    ylength = (ylim(2)-ylim(1)) / xyscaling(2);
%  
%    if ( xlength/ylength >= maxwidth/maxheight )
%        dim.x = maxwidth;
%        dim.y = maxwidth * ylength / xlength;
%    else
%        dim.x = maxheight * xlength / ylength;
%        dim.y = maxheight;
%    end
%  
%    dimension.x = dim.x;
%    dimension.y = dim.y;


%    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%    % For log-scaled axes, the pgfplot scaling means scaling powers of exp(1)
%    % (see pgfplot manual p. 55). Hence, take the natural logarithm in those
%    % cases.
%    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%    xscale  = get( handle, 'XScale' );  is_xlog = strcmp( xscale, 'log' );
%    yscale  = get( handle, 'YScale' );  is_ylog = strcmp( yscale, 'log' );
%    if is_xlog
%        q.x = log( xlim(2)/xlim(1) );
%    else
%        q.x = xlim(2) - xlim(1);
%    end
%  
%    if is_ylog
%        q.y = log( ylim(2)/ylim(1) );
%    else
%        q.y = ylim(2) - ylim(1);
%    end
%    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%  
%    % finally, set the scaling
%    scaling.x = sprintf( '%gmm', physical_length.x / q.x );
%    scaling.y = sprintf( '%gmm', physical_length.y / q.y );


  % The only way to reliably get the aspect ratio of the axes is
  % the 'Position' property. Neither 'DataAspectRatio' nor
  % 'PlotBoxAspectRatio' seem to always  yield the correct ratio.
  % Critital are for example figures with subplots.
%    position = get( handle, 'Position' )
%  
%    xscaling = 1;
%    yscaling = position(4)/position(3) * (xlim(2)-xlim(1))/(ylim(2)-ylim(1));
%  
%    % normalize: make sure the smaller side is always 1(cm)
%    xscaling = xscaling/min(xscaling,yscaling);
%    yscaling = yscaling/min(xscaling,yscaling);

  % well, it seems that MATLAB's very own print functions doesn't preserve
  % aspect ratio when printing -- we do! hence the difference in the output
%    dar = get( handle, 'DataAspectRatio' );
%    xyscaling = 1 ./ dar;

end
% =========================================================================
% *** END FUNCTION get_axes_dimensions
% =========================================================================




% =========================================================================
% *** FUNCTION escape_characters
% ***
% *** Replaces the single characters %, ', \ by their escaped versions
% *** \'', %%, \\, respectively.
% ***
% =========================================================================
function newstr = escape_characters( str )

  newstr = str;
  newstr = strrep( newstr, '''', '\''''' );
  newstr = strrep( newstr, '%' , '%%'    );
  newstr = strrep( newstr, '\' , '\\'    );

end
% =========================================================================
% *** END FUNCTION escape_characters
% =========================================================================



% =========================================================================
% *** FUNCTION boxwhere
% ***
% *** Given one or more points in 2D space 'p' and a retangular box given
% *** by 'xlim', 'ylim', this routine determines where the point sits with
% *** respect to the box.
% ***
% *** Possibilities:
% ***      1 ...... inside
% ***      2 ...... outside
% ***     -1 ...... left boundary
% ***     -2 ...... lower boundary
% ***     -3 ...... right boundary
% ***     -4 ...... top boundary
% ***
% *** If a node happens to sit in the corner of a box, return *two* values.
% ***
% =========================================================================
function l = boxwhere( p, xlim, ylim );

  global tol

  n = size(p,1);

  l = cell(n,1);
  for k = 1:n

      if    p(k,1)>xlim(1) && p(k,1)<xlim(2) ...   % inside
         && p(k,2)>ylim(1) && p(k,2)<ylim(2);
          l{k} = 1;
      elseif    p(k,1)<xlim(1) || p(k,1)>xlim(2) ...  % outside
             || p(k,2)<ylim(1) || p(k,2)>ylim(2);
          l{k} = 2;
      else % is on boundary -- but which?

          if abs(p(k,1)-xlim(1)) < tol
              l{k} = [ l{k}, -1 ];
          end
          if abs(p(k,2)-ylim(1)) < tol
              l{k} = [ l{k}, -2 ];
          end
          if abs(p(k,1)-xlim(2)) < tol
              l{k} = [ l{k}, -3 ];
          end
          if abs(p(k,2)-ylim(2)) < tol
              l{k} = [ l{k}, -4 ];
          end

          if isempty(l{k})
              error( 'matlab2tikz:boxwhere',                    ...
                     [ 'Point appears to neither sit inside, ', ...
                       'nor outsize, nor on the boundary of the box.' ] );
          end
      end

  end

end
% =========================================================================
% *** END FUNCTION boxwhere
% =========================================================================



% =========================================================================
% *** FUNCTION common_entry
% ***
% *** Returns TRUE if and only if the two vectors u, v have at least one
% *** common entry.
% ***
% =========================================================================
function out = common_entry( u, v );

  out = 0;

  usort = sort(u);
  vsort = sort(v);

  k = 1;
  l = 1;
  while k<=length(u) && l<=length(v)
      if usort(k) < vsort(l)
          k = k+1;
      elseif usort(k) > vsort(l)
          l = l+1;
      else
          out = 1;
          return
      end
  end

end
% =========================================================================
% *** END FUNCTION common_entry
% =========================================================================



% =========================================================================
% *** FUNCTION is_visible
% ***
% *** Determines whether an object is actually visible or not.
% ***
% =========================================================================
function out = is_visible( handle );

  out = strcmp( get(handle,'Visible'), 'on' );

end
% =========================================================================
% *** END FUNCTION is_visible
% =========================================================================



% =========================================================================
% *** FUNCTION normalized2physical
% ***
% *** Determines the physical width of one unit on the x-axis.
% ***
% =========================================================================
function out = normalized2physical();

  global matlab2tikz_opts

  fig  = matlab2tikz_opts.gcf;
  axes = matlab2tikz_opts.gca;

  % width of the full window
  fpos = get( fig, 'Position' );

  % width of the axes inside the window
  apos = get( axes, 'Position' );

  % width of the x-axis in pixels
  pwidth = fpos(3) * apos(3);

  % width of one unit on the x-axis on pixels
  xlim = get( axes, 'XLim' );
  unitpwidth = pwidth / (xlim(2)-xlim(1));

  dpi = get( 0, 'ScreenPixelsPerInch' );

  out.unit  = 'in';
  out.value = unitpwidth / dpi;

end
% =========================================================================
% *** END FUNCTION normalized2physical
% =========================================================================