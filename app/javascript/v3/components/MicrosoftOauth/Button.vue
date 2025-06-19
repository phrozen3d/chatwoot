<script>
import SimpleDivider from '../Divider/SimpleDivider.vue';

export default {
  components: {
    SimpleDivider,
  },
  props: {
    showSeparator: {
      type: Boolean,
      default: true,
    },
  },
  methods: {
    getMicrosoftAuthUrl() {    
      const clientId = window.chatwootConfig.microsoftOAuthClientId;
      const clientTenantId = window.chatwootConfig.microsoftOAuthTenantId;
      const baseUrl =
        `https://login.microsoftonline.com/${clientTenantId}/oauth2/v2.0/authorize`;
      const redirectUri = window.chatwootConfig.microsoftOAuthCallbackUrl;
      const responseType = 'code';
      const scope = 'openid profile email User.Read';

      // Build the query string
      const queryString = new URLSearchParams({
        client_id: clientId,
        redirect_uri: redirectUri,
        response_type: responseType,
        response_mode: 'query',
        scope: scope,
      }).toString();

      // Construct the full URL
      return `${baseUrl}?${queryString}`;
    },
  },
};
</script>

<!-- eslint-disable vue/no-unused-refs -->
<!-- Added ref for writing specs -->
<template>
  <div class="flex flex-col">
    <a
      :href="getMicrosoftAuthUrl()"
      class="inline-flex justify-center w-full"
    >
      <img
        src="assets/images/channels/ms-symbollockup_signin_dark.svg"
        alt="Microsoft Logo"
        class="w-full"
      />
    </a>
    <SimpleDivider
      v-if="showSeparator"
      ref="divider"
      :label="$t('COMMON.OR')"
      class="uppercase"
    />
  </div>
</template>
