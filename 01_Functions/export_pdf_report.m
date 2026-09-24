function pdf_path = export_pdf_report(varargin)
% EXPORT_PDF_REPORT Speichert die Konsolenausgabe als DIN-A4 PDF im Downloads-Ordner.
%
% Unterstützte Aufruf-Formen:
%   export_pdf_report(console_text, 'single', [Scenario], [output_dir])
%   export_pdf_report(console_text, 'optimization', [Targets], [output_dir])
%   export_pdf_report('single', Results, Mdata, Scenario, Weight, [Curve], [output_dir])
%   export_pdf_report('optimization', Baseline, Best, TopList, Targets, OptSettings, [output_dir])

default_downloads = fullfile(getenv('USERPROFILE'), 'Downloads');
if ~exist(default_downloads, 'dir')
    default_downloads = pwd;
end

timestamp_str = datestr(now, 'yyyy-mm-dd_HHMMSS');
date_display  = datestr(now, 'dd.mm.yyyy, HH:MM:SS');

% 1. Parameter parsen und Konsolentext ermitteln
report_type = 'single';
console_text = '';
output_dir = default_downloads;
panel_label = 'Panel';

if nargin >= 1 && (ischar(varargin{1}) || isstring(varargin{1}))
    arg1 = char(string(varargin{1}));
    
    if strcmpi(arg1, 'single')
        % Legacy-Signatur: export_pdf_report('single', Results, Mdata, Scenario, Weight, ...)
        report_type = 'single';
        if nargin >= 5
            Results  = varargin{2};
            Mdata    = varargin{3};
            Scenario = varargin{4};
            Weight   = varargin{5};
            if isfield(Scenario, 'name') && ~isempty(Scenario.name), panel_label = Scenario.name; end
            console_text = evalc('print_panel_report(Results, Mdata, Scenario, Weight);');
        end
        if nargin >= 7 && ~isempty(varargin{7}), output_dir = varargin{7}; end
        
    elseif strcmpi(arg1, 'optimization')
        % Legacy-Signatur: export_pdf_report('optimization', Baseline, Best, TopList, Targets, ...)
        report_type = 'optimization';
        if nargin >= 5
            Baseline = varargin{2};
            TopList  = varargin{4};
            Targets  = varargin{5};
            SF = 1.0;
            if isfield(Targets, 'safety_factor'), SF = Targets.safety_factor; end
            OptSettings = struct('sichtlage_active', false);
            if nargin >= 6, OptSettings = varargin{6}; end
            console_text = evalc('print_optimization_summary(Baseline, TopList, Targets, SF, OptSettings);');
            if isfield(Targets, 'Gradient') && Targets.Gradient > 0
                panel_label = sprintf('%dGrad', round(Targets.Gradient));
            end
        end
        if nargin >= 7 && ~isempty(varargin{7}), output_dir = varargin{7}; end
        
    elseif strcmpi(arg1, 'benchmark')
        % Benchmark: export_pdf_report('benchmark', console_text, [output_dir])
        report_type = 'benchmark';
        if nargin >= 2
            console_text = varargin{2};
        end
        if nargin >= 3 && ~isempty(varargin{3}), output_dir = varargin{3}; end
        
    else
        % Neue Signatur: export_pdf_report(console_text, [report_type], [meta_struct], [output_dir])
        console_text = arg1;
        if nargin >= 2
            report_type = lower(char(string(varargin{2})));
        end
        if nargin >= 3 && isstruct(varargin{3})
            meta = varargin{3};
            if isfield(meta, 'name'), panel_label = meta.name;
            elseif isfield(meta, 'Gradient'), panel_label = sprintf('%dGrad', round(meta.Gradient)); end
        end
        if nargin >= 4 && ~isempty(varargin{4})
            output_dir = varargin{4};
        end
    end
end

% Falls kein Text ermittelt werden konnte
if isempty(strtrim(console_text))
    console_text = sprintf('SES BERECHNUNGSBERICHT\nErstellt: %s\nKeine Konsolenausgabe erfasst.', date_display);
end

% 2. Dateinamen definieren
clean_label = regexprep(panel_label, '[^\w\-_]', '_');
if strcmp(report_type, 'optimization')
    pdf_filename = sprintf('SES_Bericht_Optimization_%s_%s.pdf', clean_label, timestamp_str);
    main_title   = 'FORMULA STUDENT SES – LAMINAT-OPTIMIERUNG (KONSOLENBERICHT)';
elseif strcmp(report_type, 'benchmark')
    pdf_filename = sprintf('SES_Bericht_Benchmark_%s.pdf', timestamp_str);
    main_title   = 'FORMULA STUDENT SES – BENCHMARK VALIDIERUNG (KONSOLENBERICHT)';
else
    pdf_filename = sprintf('SES_Bericht_SinglePanel_%s_%s.pdf', clean_label, timestamp_str);
    main_title   = 'FORMULA STUDENT SES – PANEL-BERECHNUNG (KONSOLENBERICHT)';
end
pdf_path = fullfile(output_dir, pdf_filename);

% 3. Text in Zeilen aufteilen & Paginierung vorbereiten
raw_lines = splitlines(console_text);
% Führende/nachfolgende Leerzeilen entfernen
while ~isempty(raw_lines) && isempty(strtrim(raw_lines{1}))
    raw_lines(1) = [];
end
while ~isempty(raw_lines) && isempty(strtrim(raw_lines{end}))
    raw_lines(end) = [];
end
if isempty(raw_lines)
    raw_lines = {'Keine Daten vorhanden.'};
end

% Einheitliche, gut lesbare Schriftgröße (7.5 pt) für alle Berichte
font_size = 7.5;
lines_per_page = 72;

n_total_lines = length(raw_lines);
n_pages = max(1, ceil(n_total_lines / lines_per_page));

% 4. PDF Seiten erzeugen und exportieren
try
    if exist(pdf_path, 'file')
        delete(pdf_path);
    end
    
    for p = 1:n_pages
        idx_start = (p - 1) * lines_per_page + 1;
        idx_end   = min(n_total_lines, p * lines_per_page);
        page_lines = raw_lines(idx_start:idx_end);
        
        fig = render_text_page(page_lines, main_title, date_display, p, n_pages, font_size);
        
        if p == 1
            exportgraphics(fig, pdf_path, 'ContentType', 'vector', 'BackgroundColor', 'white', 'Padding', 'figure');
        else
            exportgraphics(fig, pdf_path, 'ContentType', 'vector', 'BackgroundColor', 'white', 'Padding', 'figure', 'Append', true);
        end
        close(fig);
    end
    
    fprintf('\n>> Konsolenausgabe als PDF gespeichert:\n   %s\n\n', pdf_path);
    
catch ME
    warning('export_pdf_report: Fehler beim Erstellen der PDF (%s).', ME.message);
end

end

%% ------------------- HILFSFUNKTIONEN ------------------- %%

function fig = render_text_page(lines, title_str, date_str, page_num, total_pages, font_size)
% Erstellt eine DIN A4 Hochkant-Seite mit echten 23 mm Sicherheits-Druckrändern

fig = figure('Visible', 'off', 'Color', 'w', ...
             'Units', 'centimeters', 'Position', [5, 5, 21.0, 29.7], ...
             'PaperType', 'A4', 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters', ...
             'PaperSize', [21.0, 29.7], 'PaperPosition', [0, 0, 21.0, 29.7]);

% DIN A4 = 210 x 297 mm
margin_mm = 10;
margin_x  = margin_mm / 210.0; % ~0.1095
margin_y  = margin_mm / 297.0; % ~0.0774
width_x   = 1.0 - 2 * margin_x;

% Header (23 mm Abstand vom oberen Papierrand)
hdr_height = 0.045;
hdr_y      = 1.0 - margin_y - hdr_height;
ax_hdr = axes(fig, 'Position', [margin_x, hdr_y, width_x, hdr_height]);
axis(ax_hdr, 'off'); hold(ax_hdr, 'on');
xlim(ax_hdr, [0, 1]); ylim(ax_hdr, [0, 1]);
text(ax_hdr, 0.00, 1.00, title_str, 'FontName', 'Arial', 'FontSize', 10.0, 'FontWeight', 'bold', ...
    'Color', [0.10, 0.20, 0.45], 'VerticalAlignment', 'top', 'Interpreter', 'none');
text(ax_hdr, 0.00, 0.45, sprintf('Erstellt: %s   |   Quelle: MATLAB Command Window', date_str), ...
    'FontName', 'Arial', 'FontSize', 7.5, 'Color', [0.35, 0.35, 0.35], 'VerticalAlignment', 'top', 'Interpreter', 'none');
line(ax_hdr, [0, 1], [0.00, 0.00], 'Color', [0.70, 0.70, 0.70], 'LineWidth', 1.0);

% Footer (23 mm Abstand vom unteren Papierrand)
ftr_height = 0.025;
ftr_y      = margin_y;
ax_ftr = axes(fig, 'Position', [margin_x, ftr_y, width_x, ftr_height]);
axis(ax_ftr, 'off'); hold(ax_ftr, 'on');
xlim(ax_ftr, [0, 1]); ylim(ax_ftr, [0, 1]);
line(ax_ftr, [0, 1], [1.00, 1.00], 'Color', [0.80, 0.80, 0.80], 'LineWidth', 0.8);
text(ax_ftr, 0.00, 0.20, 'Formula Student Germany – SES Dokumentation (Konsolenausgabe)', ...
    'FontName', 'Arial', 'FontSize', 7.0, 'Color', [0.40, 0.40, 0.40], 'VerticalAlignment', 'bottom', 'Interpreter', 'none');
text(ax_ftr, 1.00, 0.20, sprintf('Seite %d von %d (DIN A4 hochkant, Druckränder: %d mm)', page_num, total_pages, margin_mm), ...
    'FontName', 'Arial', 'FontSize', 7.0, 'FontWeight', 'bold', 'Color', [0.30, 0.30, 0.30], ...
    'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', 'Interpreter', 'none');

% Text-Inhalt (Monospace / Courier New für exakte Spaltenausrichtung)
txt_y      = ftr_y + ftr_height + 0.015;
txt_height = hdr_y - 0.015 - txt_y;
ax_txt = axes(fig, 'Position', [margin_x, txt_y, width_x, txt_height]);
axis(ax_txt, 'off'); hold(ax_txt, 'on');
xlim(ax_txt, [0, 1]); ylim(ax_txt, [0, 1]);

content_str = strjoin(lines, '\n');
text(ax_txt, 0.00, 1.00, content_str, ...
    'FontName', 'Courier New', 'FontSize', font_size, 'FontWeight', 'normal', ...
    'Color', [0, 0, 0], 'VerticalAlignment', 'top', 'Interpreter', 'none');

end
