import { shallowMount } from '@vue/test-utils';
import MicrosoftOAuthButton from './Button.vue';

function getWrapper(showSeparator) {
  return shallowMount(MicrosoftOAuthButton, {
    propsData: { showSeparator: showSeparator },
    mocks: { $t: text => text },
  });
}

describe('MicrosoftOAuthButton.vue', () => {
  beforeEach(() => {
    window.chatwootConfig = {
      microsoftOAuthClientId: 'clientId',
      microsoftOAuthClientSecret: 'clientSecret',
      microsoftOAuthTenantId: 'tenantId'
    };
  });

  afterEach(() => {
    window.chatwootConfig = {};
  });

  it('renders the OR separator if showSeparator is true', () => {
    const wrapper = getWrapper(true);
    expect(wrapper.findComponent({ ref: 'divider' }).exists()).toBe(true);
  });

  it('does not render the OR separator if showSeparator is false', () => {
    const wrapper = getWrapper(false);
    expect(wrapper.findComponent({ ref: 'divider' }).exists()).toBe(false);
  });

  it('generates the correct Google Auth URL', () => {
    const wrapper = getWrapper();
    const microsoftAuthUrl = new URL(wrapper.vm.getMicrosoftAuthUrl());
    const params = microsoftAuthUrl.searchParams;
    expect(microsoftAuthUrl.origin).toBe('https://accounts.google.com');
    expect(microsoftAuthUrl.pathname).toBe('/o/oauth2/auth/oauthchooseaccount');
    expect(params.get('client_id')).toBe('clientId');
    expect(params.get('redirect_uri')).toBe(
      'http://localhost:3000/test-callback'
    );
    expect(params.get('response_type')).toBe('code');
    expect(params.get('scope')).toBe('email profile');

    expect(wrapper.findComponent({ ref: 'divider' }).exists()).toBe(true);
  });
});
