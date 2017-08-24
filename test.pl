   use Tk;
   use Tk::Graph;

   $mw = MainWindow->new;

   my $data = {
        Sleep   => 51,
        Work    => 135,
        Access  => 124,
        mySQL   => 5
   };

   my $ca = $mw->Graph(
                -type  => 'BARS',
                -sortnames=>'alpha',
        )->pack(
                -expand => 1,
                -fill => 'both',
        );

   $ca->configure(-variable => $data);     # bind to data

   # or ...

#    $ca->set($data);        # set data

   MainLoop;
