Map { font-directory: url(./fonts); }

@c1: #000;
@c2: rgba(0,0,0,0.8);
@font: "Cubano Regular";

#stations::glow {
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
    marker-line-width:0;
    marker-fill:@c1;
    marker-opacity:0.75;
    marker-allow-overlap:true;
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
    marker-line-width:0;
    marker-fill:@c1;
    marker-opacity:0.75;
    marker-allow-overlap:true;
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
    marker-line-width:0;
    marker-fill:@c1;
    marker-opacity:0.75;
    marker-allow-overlap:true;
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
    marker-line-width:0;
    marker-fill:@c1;
    marker-opacity:0.75;
    marker-allow-overlap:true;
  }
}

#stations::points {
  marker-width:1;
  marker-fill:#fff;
  marker-line-color:@c1;
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
  text-halo-fill:@c2;
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