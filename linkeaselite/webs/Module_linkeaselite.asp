<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>LinkEase Lite</title>
    <script src="/js/jquery.js"></script>
    <script src="/res/softcenter.js"></script>
</head>
<body>
    <div id="app">
        <h2>LinkEase Lite</h2>
        <label><input id="linkeaselite_enable" type="checkbox"> Enable</label>
        <button type="button" onclick="saveConfig()">Apply</button>
        <p id="status"></p>
    </div>
    <script>
        function saveConfig() {
            var id = Math.floor(Math.random() * 100000000);
            var enabled = document.getElementById('linkeaselite_enable').checked ? '1' : '0';
            $.ajax({
                url: '/_api/', type: 'POST', dataType: 'json',
                data: JSON.stringify({id: id, method: 'linkeaselite_config.sh', params: [1], fields: {linkeaselite_enable: enabled}})
            });
        }
    </script>
</body>
</html>
