import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('notifications')
export class Notification {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Column({ type: 'varchar', length: 50 })
  type!: string;

  @Column({ type: 'jsonb', default: {} })
  payload!: Record<string, unknown>;

  @Column({ name: 'sent_at', type: 'timestamptz' })
  sentAt!: Date;

  @Column({ name: 'read_at', type: 'timestamptz', nullable: true })
  readAt!: Date | null;
}
