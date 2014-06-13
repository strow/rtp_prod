function p = quick_satzen_cris(p)


  % [1:30] -> [58..2..58]

  %[1:15] -> [58:-3.7334:2];
  %[16:30]-> [2:+3.7334:58];

  satzen_grid = [58:-3.7334:2 2:+3.7334:58];
  p.satzen = satzen_grid(p.xtrack);


end
