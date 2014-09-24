/* 
 * Copyright 2014 Space Dynamics Laboratory - Utah State University Research Foundation.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


var doAttributes = function() {

    $.get("/openstorefront/api/v1/resource/attributes/attributetypes", function(data) {
        console.log('data', data);
        var types = data;
        for (var i = 0; i < types.length; i++) {
            setupAttributes(types[i]);
        }
    });
};


var setupAttributes = function(type) {
    $.get("/openstorefront/api/v1/resource/attributes/attributetypes/" + type.attributeType + "/attributecodes", function(codes) {
        if (codes && codes.length > 0) {
            $('#tableOfContents').append('<tr><td><span goTo="' + type.attributeType + '">' + type.description+ '</span></td></tr>');
            $('#content').append('<div id="' + type.attributeType + '" style="margin-top: 50px;"><h3>' + type.description + '</h3><div style="margin-left: 20px;"><table><tr><th>Label</th><th>Code</th><th>Description</th></tr></table></div></div>');
            $('span[goTo]').on('click', function(e) {
                e.preventDefault();
                var target = $(this).attr('goTo');
                var $target = $('#' + target);

                $('html, body').stop().animate({
                    'scrollTop': $target.offset().top - 50
                }, 400, 'swing', function() {
                });
            });
            for (var j = 0; codes && j < codes.length; j++) {
                $('#' + type.attributeType).find('table').append('<tr><td>' + codes[j].label + '</td><td>' + codes[j].attributeCodePk.attributeCode + '</td><td>'+ codes[j].description +'</td></tr></div>');

            }
        }
    });
};

var doLookups = function() {

    $.get("/openstorefront/api/v1/resource/lookuptypes", function(data) {
        console.log('data', data);
        var types = data;
        for (var i = 0; i < types.length; i++) {
            setupLookups(types[i]);
        }
    });
};


var setupLookups = function(type) {
    $.get("/openstorefront/api/v1/resource/lookuptypes/" + type.code, function(codes) {
        if (codes && codes.length > 0) {
            $('#tableOfContents').append('<tr><td><span goTo="' + type.code + '">' + type.code + '</span></td></tr>');
            $('#content').append('<div id="' + type.code + '" style="margin-top: 50px;"><h3>' + type.code + '</h3><div style="margin-left: 20px;"><table><tr><th>Description</th><th>Code</th></tr></table></div></div>');
            $('span[goTo]').on('click', function(e) {
                e.preventDefault();
                var target = $(this).attr('goTo');
                var $target = $('#' + target);

                $('html, body').stop().animate({
                    'scrollTop': $target.offset().top - 50
                }, 400, 'swing', function() {
                });
            });
            for (var j = 0; codes && j < codes.length; j++) {
                $('#' + type.code).find('table').append('<tr><td>' + codes[j].description + '</td><td>' + codes[j].code + '</td></tr></div>');
            }
        }

    });
};
