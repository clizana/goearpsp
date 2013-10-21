Quick Guide to create languages.

Change the language name, must be in caps (take the english or spanish language as example), 
put your name in the author and finally put it into the langs folder.
The most important thing is that you can only modify everething BETWEEN _ and *, and you don't 
must put other * or _ in that line.

Example:
_AUTHOR=Your name here blabla or numbers 8982*


Quick Guide to create skins.

The format of the skins is the same as languages, edit everything BETWEEN _ and *
The skins have two parts: the necesary and the optional.

Necesary

_Author=clizana* //skin author
_Name=default skin* //skin name
_fontColor=70,70,70* //font *color
_fontOverColor=175,20,20* //font over color
_color1=170,170,170* //color used in the gradient and download bar (from)
_color2=50,50,50* //color used in the gradient and download bar (to)
_color3=50,50,50* //some lines color

Optional

Here we can choose how is the background of our skin, there are three types (you must choose only ONE):

_bgFile=fondo.png* // the background will be a picture located in the skin folder, called in this case fondo.png

_bgColor=2,44,2* // the background will be only one color

_gradientBg=true* // the background will be gradient, between color1 and color2

Finally we can put our custom font located in our skin folder.

_font=ravie.ttf*
If you want to use the default font (verdana) erase the _font=* line from your skin and the verdana font will load
automatically.


*all the colors are in rgb