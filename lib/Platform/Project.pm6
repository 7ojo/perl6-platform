use v6;
use Platform::Container;
use YAMLish;

class Platform::Project {

    has Str $.config;
    has Str $.project;
    has Str $.domain = 'local';
    has Str $.data-path is rw;
    has %.defaults =
        command => '/bin/bash',
        volumes => []
        ;

    method run {
        my ($config, $projectyml-path);
        $projectyml-path = "$_/project.yml" if not $projectyml-path and "$_/project.yml".IO.e for self.project ~ "/docker", self.project;
        $config = $projectyml-path ?? load-yaml $projectyml-path.IO.slurp !! item(%.defaults);

        my $cont = self.load-cont(  
            domain      => self.domain,
            config-data => $config,
            data-path   => self.data-path
            );

        $cont.build;
        $cont.users;
        $cont.dirs;
        $cont.files;
        $cont.last-command: $cont.run;
    }

    method start { self.load-cont.start.last-command }

    method stop { self.load-cont.stop.last-command }

    method rm { self.load-cont.rm.last-command }

    method load-cont(*%values) {
        # TODO: Get more container variants here some day
        my $class = "Platform::Docker::Container";
        %values<name> = self.project.IO.basename;
        %values<projectdir> = self.project;
        require ::($class);
        ::($class).new(|%values);
    }

}
