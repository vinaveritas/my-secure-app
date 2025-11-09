import { MigrationBuilder } from 'node-pg-migrate';
export declare function up(pgm: MigrationBuilder): Promise<void>;
export declare function down(pgm: MigrationBuilder): Promise<void>;
