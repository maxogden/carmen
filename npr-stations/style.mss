Map { font-directory: url(./fonts); }

@fill: #000;
@line: rgba(255,255,255,0.2);
@halo: rgba(0,0,0,0.8);
@a1: 100;
@b1: 200;
@c1: 400;
@d1: 500;
@font: "Cubano Regular";

#stations::fill {
  marker-fill:@fill;
  marker-opacity:0.5;
  marker-line-width:0;
  marker-allow-overlap:true;
  [kw>=0] {
    [zoom=11] { marker-width:100*2*2; marker-opacity:0.500 }
    [zoom=10] { marker-width:100*2;   marker-opacity:0.625 }
    [zoom=9] { marker-width:100; }
    [zoom=8] { marker-width:100/2; }
    [zoom=7] { marker-width:100/2/2; }
    [zoom=6] { marker-width:100/2/2/2; }
    [zoom=5] { marker-width:100/2/2/2/2; }
    [zoom=4] { marker-width:100/2/2/2/2/2; }
    [zoom=3] { marker-width:100/2/2/2/2/2/2; }
  }
  [kw>=10] {
    [zoom=11] { marker-width:200*2*2; marker-opacity:0.500 }
    [zoom=10] { marker-width:200*2;   marker-opacity:0.625 }
    [zoom=9] { marker-width:200; }
    [zoom=8] { marker-width:200/2; }
    [zoom=7] { marker-width:200/2/2; }
    [zoom=6] { marker-width:200/2/2/2; }
    [zoom=5] { marker-width:200/2/2/2/2; }
    [zoom=4] { marker-width:200/2/2/2/2/2; }
    [zoom=3] { marker-width:200/2/2/2/2/2/2; }
  }
  [kw>=45] {
    [zoom=11] { marker-width:400*2*2; marker-opacity:0.500 }
    [zoom=10] { marker-width:400*2;   marker-opacity:0.625 }
    [zoom=9] { marker-width:400; }
    [zoom=8] { marker-width:400/2; }
    [zoom=7] { marker-width:400/2/2; }
    [zoom=6] { marker-width:400/2/2/2; }
    [zoom=5] { marker-width:400/2/2/2/2; }
    [zoom=4] { marker-width:400/2/2/2/2/2; }
    [zoom=3] { marker-width:400/2/2/2/2/2/2; }
  }
  [kw>=75] {
    [zoom=11] { marker-width:500*2*2; marker-opacity:0.500 }
    [zoom=10] { marker-width:500*2;   marker-opacity:0.625 }
    [zoom=9] { marker-width:500; }
    [zoom=8] { marker-width:500/2; }
    [zoom=7] { marker-width:500/2/2; }
    [zoom=6] { marker-width:500/2/2/2; }
    [zoom=5] { marker-width:500/2/2/2/2; }
    [zoom=4] { marker-width:500/2/2/2/2/2; }
    [zoom=3] { marker-width:500/2/2/2/2/2/2; }
  }
}

#stations::a {
  marker-line-color:@line;
  marker-line-width:1;
  marker-fill:transparent;
  marker-allow-overlap:true;
  [kw>=0] {
    [zoom=11] { marker-width:@a1*0.33*2*2; marker-opacity:0.500 }
    [zoom=10] { marker-width:@a1*0.33*2;   marker-opacity:0.625 }
    [zoom=9] { marker-width:@a1*0.33; }
    [zoom=8] { marker-width:@a1*0.33/2; }
    [zoom=7] { marker-width:@a1*0.33/2/2; }
    [zoom=6] { marker-width:@a1*0.33/2/2/2 * 0; }
    [zoom=5] { marker-width:@a1*0.33/2/2/2/2 * 0; }
    [zoom=4] { marker-width:@a1*0.33/2/2/2/2/2 * 0; }
    [zoom=3] { marker-width:@a1*0.33/2/2/2/2/2/2 * 0; }
  }
  [kw>=10] {
    [zoom=11] { marker-width:@b1*0.33*2*2; marker-opacity:0.500 }
    [zoom=10] { marker-width:@b1*0.33*2;   marker-opacity:0.625 }
    [zoom=9] { marker-width:@b1*0.33; }
    [zoom=8] { marker-width:@b1*0.33/2; }
    [zoom=7] { marker-width:@b1*0.33/2/2; }
    [zoom=6] { marker-width:@b1*0.33/2/2/2; }
    [zoom=5] { marker-width:@b1*0.33/2/2/2/2; }
    [zoom=4] { marker-width:@b1*0.33/2/2/2/2/2; }
    [zoom=3] { marker-width:@b1*0.33/2/2/2/2/2/2; }
  }
  [kw>=45] {
    [zoom=11] { marker-width:@c1*0.33*2*2; marker-opacity:0.500 }
    [zoom=10] { marker-width:@c1*0.33*2;   marker-opacity:0.625 }
    [zoom=9] { marker-width:@c1*0.33; }
    [zoom=8] { marker-width:@c1*0.33/2; }
    [zoom=7] { marker-width:@c1*0.33/2/2; }
    [zoom=6] { marker-width:@c1*0.33/2/2/2; }
    [zoom=5] { marker-width:@c1*0.33/2/2/2/2; }
    [zoom=4] { marker-width:@c1*0.33/2/2/2/2/2; }
    [zoom=3] { marker-width:@c1*0.33/2/2/2/2/2/2; }
  }
  [kw>=75] {
    [zoom=11] { marker-width:@d1*0.33*2*2; marker-opacity:0.500 }
    [zoom=10] { marker-width:@d1*0.33*2;   marker-opacity:0.625 }
    [zoom=9] { marker-width:@d1*0.33; }
    [zoom=8] { marker-width:@d1*0.33/2; }
    [zoom=7] { marker-width:@d1*0.33/2/2; }
    [zoom=6] { marker-width:@d1*0.33/2/2/2; }
    [zoom=5] { marker-width:@d1*0.33/2/2/2/2; }
    [zoom=4] { marker-width:@d1*0.33/2/2/2/2/2; }
    [zoom=3] { marker-width:@d1*0.33/2/2/2/2/2/2; }
  }
}

#stations::b {
  marker-line-color:@line;
  marker-line-width:1;
  marker-fill:transparent;
  marker-allow-overlap:true;
  [kw>=0] {
    [zoom=11] { marker-width:@a1*0.66*2*2; marker-opacity:0.500 }
    [zoom=10] { marker-width:@a1*0.66*2;   marker-opacity:0.625 }
    [zoom=9] { marker-width:@a1*0.66; }
    [zoom=8] { marker-width:@a1*0.66/2; }
    [zoom=7] { marker-width:@a1*0.66/2/2; }
    [zoom=6] { marker-width:@a1*0.66/2/2/2 * 0; }
    [zoom=5] { marker-width:@a1*0.66/2/2/2/2 * 0; }
    [zoom=4] { marker-width:@a1*0.66/2/2/2/2/2 * 0; }
    [zoom=3] { marker-width:@a1*0.66/2/2/2/2/2/2 * 0; }
  }
  [kw>=10] {
    [zoom=11] { marker-width:@b1*0.66*2*2; marker-opacity:0.500 }
    [zoom=10] { marker-width:@b1*0.66*2;   marker-opacity:0.625 }
    [zoom=9] { marker-width:@b1*0.66; }
    [zoom=8] { marker-width:@b1*0.66/2; }
    [zoom=7] { marker-width:@b1*0.66/2/2; }
    [zoom=6] { marker-width:@b1*0.66/2/2/2; }
    [zoom=5] { marker-width:@b1*0.66/2/2/2/2; }
    [zoom=4] { marker-width:@b1*0.66/2/2/2/2/2; }
    [zoom=3] { marker-width:@b1*0.66/2/2/2/2/2/2; }
  }
  [kw>=45] {
    [zoom=11] { marker-width:@c1*0.66*2*2; marker-opacity:0.500 }
    [zoom=10] { marker-width:@c1*0.66*2;   marker-opacity:0.625 }
    [zoom=9] { marker-width:@c1*0.66; }
    [zoom=8] { marker-width:@c1*0.66/2; }
    [zoom=7] { marker-width:@c1*0.66/2/2; }
    [zoom=6] { marker-width:@c1*0.66/2/2/2; }
    [zoom=5] { marker-width:@c1*0.66/2/2/2/2; }
    [zoom=4] { marker-width:@c1*0.66/2/2/2/2/2; }
    [zoom=3] { marker-width:@c1*0.66/2/2/2/2/2/2; }
  }
  [kw>=75] {
    [zoom=11] { marker-width:@d1*0.66*2*2; marker-opacity:0.500 }
    [zoom=10] { marker-width:@d1*0.66*2;   marker-opacity:0.625 }
    [zoom=9] { marker-width:@d1*0.66; }
    [zoom=8] { marker-width:@d1*0.66/2; }
    [zoom=7] { marker-width:@d1*0.66/2/2; }
    [zoom=6] { marker-width:@d1*0.66/2/2/2; }
    [zoom=5] { marker-width:@d1*0.66/2/2/2/2; }
    [zoom=4] { marker-width:@d1*0.66/2/2/2/2/2; }
    [zoom=3] { marker-width:@d1*0.66/2/2/2/2/2/2; }
  }
}

#stations::points {
  marker-width:1;
  marker-fill:#fff;
  marker-line-color:@halo;
  marker-line-width:0;
  marker-allow-overlap:true;
  [zoom>=5] { marker-width:2; }
  [zoom>=7] { marker-width:4; }
  [zoom>=9] { marker-width:8; marker-line-width:1; }
  [zoom>=11] { marker-width:16; marker-line-width:2; }
}

#stations::labels[zoom>=7] {
  text-name:"[search].replace(',','')";
  text-size:10;
  text-vertical-alignment:middle;
  text-dx:8;
  text-fill:#fff;
  text-halo-fill:@halo;
  text-halo-radius:1;
  text-face-name:@font;
  text-allow-overlap:true;
  [zoom>=9]  { text-dx:10; }
  [zoom>=10] { text-dx:12; }
  [zoom>=11] { text-dx:16; text-halo-radius:2; }
  [zoom>=8][kw >= 10] { text-size:12; }
  [zoom>=9][kw >= 10] { text-size:16; text-dx:10; }
  [zoom>=10][kw >= 10] { text-size:20; text-dx:12; }
  [zoom>=11][kw >= 10] { text-size:24; text-dx:16; }
}