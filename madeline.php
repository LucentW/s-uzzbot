#!/usr/bin/env php
<?php
/*
Copyright 2016-2017 Daniil Gentili
(https://daniil.it)
This file is part of MadelineProto.
MadelineProto is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
MadelineProto is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU Affero General Public License for more details.
You should have received a copy of the GNU General Public License along with MadelineProto.
If not, see <http://www.gnu.org/licenses/>.
*/

//See https://github.com/danog/MadelineProto/blob/master/lua/madeline.php

require 'Madeline_lua_shim/vendor/autoload.php';
$Lua = false;

try {
    $Lua = new \danog\MadelineProto\Lua('start.lua', \danog\MadelineProto\Serialization::deserialize('bot.madeline'));
} catch (\danog\MadelineProto\Exception $e) {
    die($e->getMessage().PHP_EOL);
}

function ser()
{
    global $Lua;
    $Lua->MadelineProto->serialize('bot.madeline');
}

$Lua->registerCallback('serialize', 'ser');

if (!file_exists('download')) {
    mkdir('download');
}

$Lua->madeline_update_callback(['_' => 'init']);
$offset = 0;
$lastSer = time();
while (true) {
    $updates = $Lua->MadelineProto->API->get_updates(['offset' => $offset, 'limit' => 50, 'timeout' => 0]);
    foreach ($updates as $update) {
        $offset = $update['update_id'] + 1;
        $Lua->madeline_update_callback($update['update']);
        echo PHP_EOL;
    }

    $Lua->doCrons();
    if (time()-60 >= $lastSer) {
        ser();
        $lastSer = time();
    }
}
