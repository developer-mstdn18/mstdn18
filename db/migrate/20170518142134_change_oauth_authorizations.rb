class ChengeOAuthAuthorizations < ActiveRecord::Migration[5.0]
    def up
        change_column_null :oauth_authorizations, :name, true
    end

    def down
        change_column_null :oauth_authorizations, :name, false
    end
end
