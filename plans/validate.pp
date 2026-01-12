plan control_repo::validate(
  TargetSpec $targets = 'agents'
) {
  $results = run_command('/opt/puppetlabs/bin/facter os.name', $targets, { '_catch_errors' => true })

  $output = {
    'targets' => $targets,
    'results' => $results,
  }

  return $output
}
