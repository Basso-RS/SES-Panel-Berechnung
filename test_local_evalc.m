a = 1;
console_text = evalc('test_local();');
fprintf('Result: %s
', console_text);

function test_local()
    fprintf('Hello from local func');
end
