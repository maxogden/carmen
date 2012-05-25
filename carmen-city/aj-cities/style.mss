Map {
  background-color: #b8dee6;
}

#countries[zoom<=7],
#land[zoom>=6] {
  polygon-fill: #fff;
  polygon-gamma:0.6;
}
#countries {
  line-width: 0.5;
}

#placeX {
  [type='city'] { polygon-fill:#f00; }
  [type='town'] { polygon-fill:#f80; }
  [type='village'] { polygon-fill:#ff0; }
  composite-operation:multiply;
  ::l[zoom>9] {
    text-name: "[name_loc]";
    text-face-name: "Arial Regular";
    text-halo-radius: 2;
    text-halo-fill: #fff;
  }
}

#adminX[admin_level>=8] {
  polygon-fill:#fff;
  [admin_level=10] { polygon-fill:#00f; }
  [admin_level=9] { polygon-fill:#08f; }
  [admin_level=8] { polygon-fill:#0ff; }
  composite-operation:multiply;
  ::l[zoom>9] {
      text-name: "[name_loc]";
    text-face-name: "Arial Regular";
    text-halo-radius: 2;
    text-halo-fill: #fff;
  }
}

#addr_all[count>0] {
  polygon-fill:#30f;
  polygon-opacity: 0.2;
  line-color: fadeout(#00f,0.1);
  composite-operation: color-burn;
  ::l[zoom>9] {
    text-name: "[type]";
    text-face-name: "Arial Regular";
    text-fill: rgba(0,0,200,0.5);
    //text-halo-radius: 2;
    //text-halo-fill: #fff;
  }
}

#addr_point {
  marker-fill: #333;
  marker-width: 3;
  marker-opacity: 0.5;
  marker-line-width: 0;
}

#addr_poly {
  polygon-fill: #333;
  polygon-opacity: 0.5;
}

#addr_line {
  line-color: #333;
  line-opacity: 0.5;
}