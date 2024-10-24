import { RuleConfigSeverity } from '@commitlint/types';

export default {
  extends: ['@commitlint/config-conventional'],
  parserPreset: 'conventional-changelog-conventionalcommits',
  rules: {
    'scope-enum': [RuleConfigSeverity.Error, 'always', [
        '',
        'ci',
        'deps',
        'assign',
        'assign-container',
    ]],
    'subject-case': [RuleConfigSeverity.Error, 'never', []],
  }
};
