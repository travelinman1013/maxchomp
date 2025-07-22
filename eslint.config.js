export default [
  {
    files: ['**/*.js', '**/*.jsx', '**/*.ts', '**/*.tsx'],
    rules: {
      // Complexity and size rules following TDD best practices
      'complexity': ['warn', 10],
      'max-depth': ['warn', 4],
      'max-lines-per-function': ['warn', 50],
      'max-nested-callbacks': ['warn', 3],
      'max-params': ['warn', 4],
    }
  }
];
EOF < /dev/null