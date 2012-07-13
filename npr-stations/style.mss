@c1: #90CD49;
@c2: #6FCA5A;
@c3: #4BC66B;
@c4: #0FC17D;

#stations::glow {
  [kw>=0] {
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
    [zoom=9] { marker-width:200; }
    [zoom=8] { marker-width:200/2; }
    [zoom=7] { marker-width:200/2/2; }
    [zoom=6] { marker-width:200/2/2/2; }
    [zoom=5] { marker-width:200/2/2/2/2; }
    [zoom=4] { marker-width:200/2/2/2/2/2; }
    [zoom=3] { marker-width:200/2/2/2/2/2/2; }
    marker-line-width:0;
    marker-fill:@c2;
    marker-opacity:0.75;
    marker-allow-overlap:true;
  }
  [kw>=45] {
    [zoom=9] { marker-width:400; }
    [zoom=8] { marker-width:400/2; }
    [zoom=7] { marker-width:400/2/2; }
    [zoom=6] { marker-width:400/2/2/2; }
    [zoom=5] { marker-width:400/2/2/2/2; }
    [zoom=4] { marker-width:400/2/2/2/2/2; }
    [zoom=3] { marker-width:400/2/2/2/2/2/2; }
    marker-line-width:0;
    marker-fill:@c3;
    marker-opacity:0.75;
    marker-allow-overlap:true;
  }
  [kw>=75] {
    [zoom=9] { marker-width:500; }
    [zoom=8] { marker-width:500/2; }
    [zoom=7] { marker-width:500/2/2; }
    [zoom=6] { marker-width:500/2/2/2; }
    [zoom=5] { marker-width:500/2/2/2/2; }
    [zoom=4] { marker-width:500/2/2/2/2/2; }
    [zoom=3] { marker-width:500/2/2/2/2/2/2; }
    marker-line-width:0;
    marker-fill:@c4;
    marker-opacity:0.75;
    marker-allow-overlap:true;
  }
}

#stations::points {
  marker-width:1;
  marker-fill:#fff;
  marker-line-width:0;
  marker-allow-overlap:true;
  [zoom>=5] { marker-width:2; }
  [zoom>=7] { marker-width:4; }
}

#stations::labels[zoom>=7] {
  text-name:"[search].replace(',','')";
  text-size:10;
  [zoom>=8][kw >= 10] { text-size:12; }
  [zoom>=9][kw >= 10] { text-size:16; }
  text-vertical-alignment:middle;
  text-dx:8;
  text-fill:#fff;
  text-face-name:"Arial Bold";
  text-allow-overlap:true;
}