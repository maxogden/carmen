Map { font-directory: url(./fonts); }

@cell: rgba(144,160,176,0.5);
@spn:  -20;
@sat:  10;
@w:    1;

#data::fill {
  line-width:0.5;
  line-color:#fff;
  [count > 0]   { polygon-fill:@cell;}
  [count > 10]  { polygon-fill:saturate(spin(@cell,@spn),    @sat*1%); }
  [count > 20]  { polygon-fill:saturate(spin(@cell,@spn*2),  @sat*2%); }
  [count > 30]  { polygon-fill:saturate(spin(@cell,@spn*3),  @sat*3%); }
  [count > 40]  { polygon-fill:saturate(spin(@cell,@spn*4),  @sat*4%); }
  [count > 50]  { polygon-fill:saturate(spin(@cell,@spn*5),  @sat*5%); }
  [count > 60]  { polygon-fill:saturate(spin(@cell,@spn*6),  @sat*6%); }
  [count > 70]  { polygon-fill:saturate(spin(@cell,@spn*7),  @sat*7%); }
  [count > 80]  { polygon-fill:saturate(spin(@cell,@spn*8),  @sat*8%); }
  [count > 90]  { polygon-fill:saturate(spin(@cell,@spn*9),  @sat*9%); }
  [count > 100] { polygon-fill:saturate(spin(@cell,@spn*10), @sat*10%); }
  [count > 125] { polygon-fill:saturate(spin(@cell,@spn*11), @sat*11%); }
  [count > 150] { polygon-fill:saturate(spin(@cell,@spn*12), @sat*12%); }
  [count > 175] { polygon-fill:saturate(spin(@cell,@spn*13), @sat*13%); }
  [count > 200] { polygon-fill:saturate(spin(@cell,@spn*14), @sat*14%); }
}

#data::text[zoom>=5] {
  text-name: "[count]";
  text-face-name: "Franchise Regular";
  text-fill:#fff;
  text-size:8;
  [zoom>=6] { text-size:16; }
  [zoom>=7] { text-size:24; }
  [zoom>=8] { text-size:32; }
  [zoom>=9] { text-size:48; }
  [zoom>=10] { text-size:64; }
}
