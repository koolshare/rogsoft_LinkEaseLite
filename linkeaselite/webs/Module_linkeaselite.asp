<!DOCTYPE html
    PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="X-UA-Compatible" content="IE=Edge" />
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta HTTP-EQUIV="Pragma" CONTENT="no-cache" />
    <meta HTTP-EQUIV="Expires" CONTENT="-1" />
    <link rel="shortcut icon" href="images/favicon.png" />
    <link rel="icon" href="images/favicon.png" />
    <title>软件中心 - LinkEase Lite</title>
    <link rel="stylesheet" type="text/css" href="index_style.css" />
    <link rel="stylesheet" type="text/css" href="form_style.css" />
    <link rel="stylesheet" type="text/css" href="usp_style.css" />
    <link rel="stylesheet" type="text/css" href="ParentalControl.css">
    <link rel="stylesheet" type="text/css" href="css/element.css">
    <link rel="stylesheet" type="text/css" href="res/softcenter.css">
    <script>
        (function () {
            window.__linkeaselite_amd_define_exists = Object.prototype.hasOwnProperty.call(window, "define");
            window.__linkeaselite_amd_define = window.define;
            if (window.define && window.define.amd) {
                window.define = undefined;
            }
        })();
    </script>
    <script language="JavaScript" type="text/javascript" src="/js/jquery.js"></script>
    <script>
        (function () {
            if (window.__linkeaselite_amd_define_exists) {
                window.define = window.__linkeaselite_amd_define;
            } else {
                try {
                    delete window.define;
                } catch (e) {
                    window.define = undefined;
                }
            }
            try {
                delete window.__linkeaselite_amd_define;
                delete window.__linkeaselite_amd_define_exists;
            } catch (e) {
                window.__linkeaselite_amd_define = undefined;
                window.__linkeaselite_amd_define_exists = undefined;
            }
        })();
    </script>
    <script language="JavaScript" type="text/javascript" src="/state.js"></script>
    <script language="JavaScript" type="text/javascript" src="/popup.js"></script>
    <script language="JavaScript" type="text/javascript" src="/validator.js"></script>
    <script language="JavaScript" type="text/javascript" src="/help.js"></script>
    <script language="JavaScript" type="text/javascript" src="/general.js"></script>
    <script language="JavaScript" type="text/javascript" src="/switcherplugin/jquery.iphone-switch.js"></script>
    <script language="JavaScript" type="text/javascript" src="/res/softcenter.js"></script>
    <style>
        .linkeaselite_btn {
            border: 1px solid #222;
            background: linear-gradient(to bottom, #003333 0%, #000000 100%);
            font-size: 10pt;
            color: #fff;
            padding: 5px 5px;
            border-radius: 5px;
            width: 18%;
        }

        .linkeaselite_btn:hover {
            border: 1px solid #222;
            background: linear-gradient(to bottom, #27c9c9 0%, #279fd9 100%);
            font-size: 10pt;
            color: #fff;
            padding: 5px 5px;
            border-radius: 5px;
            width: 18%;
        }

        .linkeaselite_msg {
            margin: 10px;
        }
    </style>
    <script>
        var r_lan_ipaddr = "<% nvram_get(lan_ipaddr); %>";
        var params_check = ["linkeaselite_enable"];
        var dbus = {};

        function init() {
            show_menu(menu_hook);
            get_dbus_data();
            get_status();
        }

        function menu_hook(title, tab) {
            tabtitle[tabtitle.length - 1] = new Array("", "LinkEase Lite");
            tablink[tablink.length - 1] = new Array("", "Module_linkeaselite.asp");
        }

        function get_dbus_data() {
            $.ajax({
                type: "GET",
                url: "/_api/linkeaselite",
                dataType: "json",
                async: false,
                success: function (data) {
                    dbus = data.result[0] || {};
                    conf_to_obj();
                    generate_link();
                }
            });
        }

        function conf_to_obj() {
            for (var i = 0; i < params_check.length; i++) {
                if (dbus[params_check[i]]) {
                    E(params_check[i]).checked = dbus[params_check[i]] == "1";
                }
            }
        }

        function save() {
            for (var i = 0; i < params_check.length; i++) {
                dbus[params_check[i]] = E(params_check[i]).checked ? "1" : "0";
            }
            showLoading();
            push_data(dbus, 1);
        }

        function push_data(obj, arg) {
            var id = parseInt(Math.random() * 100000000);
            var postData = { "id": id, "method": "linkeaselite_config.sh", "params": [arg], "fields": obj };
            $.ajax({
                url: "/_api/",
                cache: false,
                type: "POST",
                dataType: "json",
                data: JSON.stringify(postData),
                success: function (response) {
                    if (response.result == id) {
                        refreshpage();
                    }
                }
            });
        }

        function generate_link() {
            var management_url = "http://" + r_lan_ipaddr + ":8897";
            E("linkeaselite_guide").href = management_url;
            E("linkeaselite_website").href = management_url;
            if (dbus["linkeaselite_enable"] != "1") {
                E("linkeaselite_guide").style.display = "none";
                E("linkeaselite_website").style.display = "none";
            } else {
                E("linkeaselite_guide").style.display = "";
                E("linkeaselite_website").style.display = "";
            }
        }

        function get_status() {
            var id = parseInt(Math.random() * 100000000);
            var postData = { "id": id, "method": "linkeaselite_status.sh", "params": [1], "fields": "" };
            $.ajax({
                type: "POST",
                cache: false,
                url: "/_api/",
                data: JSON.stringify(postData),
                dataType: "json",
                success: function (response) {
                    E("status").innerHTML = response.result;
                    setTimeout("get_status();", 10000);
                },
                error: function () {
                    setTimeout("get_status();", 5000);
                }
            });
        }
    </script>
</head>

<body onload="init();">
    <div id="TopBanner"></div>
    <div id="Loading" class="popup_bg"></div>
    <iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>
    <input type="hidden" name="current_page" value="Module_linkeaselite.asp">
    <input type="hidden" name="next_page" value="Module_linkeaselite.asp">
    <input type="hidden" name="group_id" value="">
    <input type="hidden" name="modified" value="0">
    <input type="hidden" name="action_mode" value="">
    <input type="hidden" name="action_script" value="">
    <input type="hidden" name="action_wait" value="8">
    <input type="hidden" name="first_time" value="">
    <input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>">
    <input type="hidden" name="SystemCmd" onkeydown="onSubmitCtrl(this, ' Refresh ')" value="">
    <input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>">
    <table class="content" align="center" cellpadding="0" cellspacing="0">
        <tr>
            <td width="17">&nbsp;</td>
            <td valign="top" width="202">
                <div id="mainMenu"></div>
                <div id="subMenu"></div>
            </td>
            <td valign="top">
                <div id="tabMenu" class="submenuBlock"></div>
                <table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
                    <tr>
                        <td align="left" valign="top">
                            <table width="760px" border="0" cellpadding="5" cellspacing="0" bordercolor="#6b8fa3"
                                class="FormTitle" id="FormTitle">
                                <tr>
                                    <td bgcolor="#4D595D" colspan="3" valign="top">
                                        <div>&nbsp;</div>
                                        <div class="formfonttitle">LinkEase Lite 远程文件管理</div>
                                        <div style="float:right; width:15px; height:25px;margin-top:-20px">
                                            <img id="return_btn" onclick="reload_Soft_Center();" align="right"
                                                style="cursor:pointer;position:absolute;margin-left:-30px;margin-top:-25px;"
                                                title="返回软件中心" src="/images/backprev.png"
                                                onMouseOver="this.src='/images/backprevclick.png'"
                                                onMouseOut="this.src='/images/backprev.png'"></img>
                                        </div>
                                        <div style="margin:0px 0 10px 5px;" class="splitLine"></div>
                                        <div class="SimpleNote">
                                            <li>LinkEase Lite 仅包含核心远程文件访问与轻量运行能力，适合空间和内存较小的路由器。</li>
                                            <li>Lite 与默认 LinkEase 可以同时安装，但同一时间只运行一个服务，共用端口 8897。</li>
                                        </div>
                                        <table width="100%" border="1" align="center" cellpadding="4" cellspacing="0"
                                            bordercolor="#6b8fa3" class="FormTable">
                                            <thead>
                                                <tr>
                                                    <td colspan="2">LinkEase Lite - 设置</td>
                                                </tr>
                                            </thead>
                                            <tr id="switch_tr">
                                                <th>
                                                    <label>开关</label>
                                                </th>
                                                <td colspan="2">
                                                    <div class="switch_field" style="display:table-cell;float: left;">
                                                        <label for="linkeaselite_enable">
                                                            <input id="linkeaselite_enable" class="switch"
                                                                type="checkbox" style="display: none;">
                                                            <div class="switch_container">
                                                                <div class="switch_bar"></div>
                                                                <div class="switch_circle transition_style">
                                                                    <div></div>
                                                                </div>
                                                            </div>
                                                        </label>
                                                    </div>
                                                </td>
                                            </tr>
                                            <tr id="linkeaselite_status">
                                                <th>运行状态</th>
                                                <td><span id="status">获取中...</span></td>
                                            </tr>
                                            <tr id="linkeaselite_manage">
                                                <th>管理/帮助</th>
                                                <td id="linkeaselite_pre">
                                                    <a type="button" id="linkeaselite_guide"
                                                        class="linkeaselite_btn" target="_blank">配置中心</a>
                                                    <a type="button" id="linkeaselite_website"
                                                        class="linkeaselite_btn" href="" target="_blank">打开LinkEase</a>
                                                </td>
                                            </tr>
                                        </table>
                                        <div class="linkeaselite_msg">
                                            <i>使用流程：</i>
                                            <div class="linkeaselite_msg_info">
                                                <li>启动插件：打开上方开关按钮后点击提交。</li>
                                                <li>绑定设备：点击配置中心进入 LinkEase 页面，登录易有云账号并绑定设备。</li>
                                                <li>访问文件：绑定成功后，可通过易有云 APP 或电脑客户端访问路由器文件。</li>
                                            </div>
                                        </div>
                                        <div style="margin:30px 0 10px 5px;" class="splitLine"></div>
                                        <div id="warning" style="font-size:14px;margin:20px auto;"></div>
                                        <div class="apply_gen">
                                            <input class="button_gen" id="cmdBtn" onClick="save()" type="button"
                                                value="提交" />
                                        </div>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>
            </td>
            <td width="10" align="center" valign="top"></td>
        </tr>
    </table>
    <div id="footer"></div>
    <div id="OverlayMask" class="popup_bg">
        <div align="center">
            <iframe src="" frameborder="0" scrolling="no" id="popupframe" width="400" height="400"
                allowtransparency="true" style="margin-top:150px;"></iframe>
        </div>
    </div>
</body>

</html>
