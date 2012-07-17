@bg: #000c10;
@mw: 20;
@bw: 10;

Map {
  background-color: @bg;
  font-directory: url(./fonts);
}

#named::dots,
#stars::dots {
  [color <= 0] {
    marker-fill:fadeout(#DDFFFC, 20%);
    marker-line-color:fadeout(#DDFFFC, 20%);
    }
  [color > 0][color <= 0.5] {
    marker-fill:fadeout(#B9FFF9, 20%);
    marker-line-color:fadeout(#B9FFF9, 20%);
    }
  [color > 0.5] {
    marker-fill:fadeout(#FFEBA8, 20%);
    marker-line-color:fadeout(#FFEBA8, 20%);
    }
  [zoom >= 0] {
    marker-width:0.25;
    marker-line-width:0.5;
    marker-line-opacity:0.1;
    marker-allow-overlap:true;
    [mag >= 0]  { marker-width:0.5; marker-line-width:1.0;}
    [mag >= 2]  { marker-width:0.75;marker-line-width:1.5;}
    [mag >= 4]  { marker-width:1.0; marker-line-width:2.0;}
    [mag >= 6]  { marker-width:1.25;marker-line-width:2.5;}
    [mag >= 8]  { marker-width:1.5; marker-line-width:3.0;}
    [mag >= 10] { marker-width:1.75;marker-line-width:3.5;}
  }
  [zoom >= 3] {
    marker-width:0.5;
    marker-line-width:1.0;
    marker-line-opacity:0.1;
    marker-allow-overlap:true;
    [mag >= 0]  { marker-width:1.0; marker-line-width:2.0;}
    [mag >= 2]  { marker-width:1.5; marker-line-width:3.0;}
    [mag >= 4]  { marker-width:2.0; marker-line-width:4.0;}
    [mag >= 6]  { marker-width:2.5; marker-line-width:5.0;}
    [mag >= 8]  { marker-width:3.0; marker-line-width:6.0;}
    [mag >= 10] { marker-width:3.5; marker-line-width:7.0;}
  }
  [zoom >= 6] {
    marker-width:1;
    marker-line-width:2.0;
    marker-line-opacity:0.1;
    marker-allow-overlap:true;
    [mag >= 0]  { marker-width:2.0; marker-line-width:4.0;}
    [mag >= 2]  { marker-width:3.0; marker-line-width:6.0;}
    [mag >= 4]  { marker-width:4.0; marker-line-width:8.0;}
    [mag >= 6]  { marker-width:5.0; marker-line-width:10.0;}
    [mag >= 8]  { marker-width:6.0; marker-line-width:12.0;}
    [mag >= 10] { marker-width:7.0; marker-line-width:14.0;}
  }
}

#named::markedBuffer[zoom>=3][hasname=1] {
  marker-width:@mw;
  marker-line-width:@bw;
  marker-line-color:fadeout(@bg, 50%);
  marker-fill:transparent;
  marker-allow-overlap:true;
  [zoom >= 4] { marker-width:@mw*2; marker-line-width:@bw*2; }
  [zoom >= 5] { marker-width:@mw*4; marker-line-width:@bw*4; }
  [zoom >= 6] { marker-width:@mw*8; marker-line-width:@bw*8; }
  [zoom >= 7] { marker-width:@mw*12; marker-line-width:@bw*12; }
  [zoom >= 8] { marker-width:@mw*16; marker-line-width:@bw*16; }
  }

#named::marked[zoom>=3][hasname=1] {
  marker-width:@mw;
  marker-line-width:0.75;
  marker-line-color:#ddd;
  marker-fill:transparent;
  marker-allow-overlap:true;
  [zoom >= 4] { marker-width:@mw*2 }
  [zoom >= 5] { marker-width:@mw*4 }
  [zoom >= 6] { marker-width:@mw*8 }
  [zoom >= 7] { marker-width:@mw*12 }
  [zoom >= 8] { marker-width:@mw*16 }
}

#named::iddline[zoom>=6][hasid=1] {
  text-name:'"|"';
  text-size:7;
  text-dy:4;
  text-face-name:'DejaVu Sans Bold';
  text-allow-overlap:true;
  text-fill:#999;
  [zoom >= 7] { text-size:9; text-dy:6; }
  [zoom >= 8] { text-size:11; text-dy:8; }
}

#named::idd[zoom>=6][hasid=1] {
  text-name:'[name]';
  text-face-name:'Carton Slab';
  text-size:10;
  text-fill:#ddd;
  text-halo-fill:#000;
  text-halo-radius:1;
  text-allow-overlap:true;
  text-dy:15;
  [zoom >= 7] { text-size:12; text-dy:20; }
  [zoom >= 8] { text-size:16; text-dy:25; }
}

#named::named[zoom>=4][hasname=1] {
  text-name:'[name]';
  text-face-name:'Carton Slab';
  text-size:10;
  text-fill:#ddd;
  text-halo-fill:#000;
  text-halo-radius:1;
  text-allow-overlap:true;
  text-dy:5;
  [zoom >= 5] { text-size:12; text-dy:10; }
  [zoom >= 6] { text-size:16; text-dy:15; }
  [zoom >= 7] { text-size:20; text-dy:25; }
  [zoom >= 8] { text-size:24; text-dy:40; }
}